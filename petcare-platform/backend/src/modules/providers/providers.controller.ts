import { Body, Controller, Delete, Get, Param, Post, Query, Req, UseGuards, BadRequestException } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PrismaService } from '../../common/prisma.module';
import { ServiceType, DocumentType } from '@prisma/client';

class SetAvailabilityDto {
  isAvailable: boolean;
  lat?: number;
  lng?: number;
}

class AddServiceDto {
  serviceType: ServiceType;
  priceInr: number;
  durationMin: number;
}

class ProviderOnboardingDto {
  name?: string;
  email?: string;
  profilePhoto?: string;
  dateOfBirth?: string;
  addressCity?: string;
  emergencyContact?: string;
  bio?: string;
  yearsExperience?: number;
  serviceRadiusKm?: number;
  skills?: string;
  services?: Array<{ serviceType: ServiceType; priceInr: number; durationMin?: number }>;
}

class AddDocumentDto {
  documentType: DocumentType;
  title: string;
  issuingOrg?: string;
  documentUrl: string;
  issueDate?: string;
  expiryDate?: string;
}

@Controller('providers')
export class ProvidersController {
  constructor(private prisma: PrismaService) {}

  // Public: find available providers near the pet owner for a given service.
  // Calculates real distance from owner GPS coordinates and sorts by distance.
  // ONLY APPROVED/VERIFIED providers with an active service are discoverable.
  @Get('nearby')
  async nearby(
    @Query('serviceType') serviceType?: ServiceType,
    @Query('lat') lat?: string,
    @Query('lng') lng?: string,
  ) {
    const providers = await this.prisma.providerProfile.findMany({
      where: {
        isAvailable: true,
        verificationStatus: { in: ['APPROVED', 'VERIFIED'] as any },
        ...(serviceType ? { servicesOffered: { some: { serviceType } } } : {}),
      },
      include: { servicesOffered: true, user: true },
      take: 20,
    });

    const parsedLat = lat ? parseFloat(lat) : null;
    const parsedLng = lng ? parseFloat(lng) : null;

    if (parsedLat !== null && parsedLng !== null && !isNaN(parsedLat) && !isNaN(parsedLng)) {
      return providers
        .map((p) => {
          const pLat = p.currentLat ?? parsedLat;
          const pLng = p.currentLng ?? parsedLng;
          const dMeters = haversineMeters(parsedLat, parsedLng, pLat, pLng);
          return {
            ...p,
            distanceKm: parseFloat((dMeters / 1000).toFixed(1)),
          };
        })
        .sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
    }

    return providers;
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('profile')
  async getProfile(@Req() req: any) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: {
        providerProfile: {
          include: {
            servicesOffered: true,
            documents: { orderBy: { createdAt: 'desc' } },
          },
        },
      },
    });
    return user;
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('status')
  async getStatus(@Req() req: any) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: {
        providerProfile: {
          include: {
            documents: { orderBy: { createdAt: 'desc' } },
            servicesOffered: true,
          },
        },
      },
    });

    if (!user || !user.providerProfile) {
      throw new BadRequestException('Provider profile not found');
    }

    const p = user.providerProfile;
    return {
      id: p.id,
      verificationStatus: p.verificationStatus,
      rejectionReason: p.rejectionReason,
      suspensionReason: p.suspensionReason,
      isAvailable: p.isAvailable,
      ratingAvg: p.ratingAvg,
      ratingCount: p.ratingCount,
      documents: p.documents,
      servicesOffered: p.servicesOffered,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        profilePhoto: user.profilePhoto,
      },
    };
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('onboarding')
  async completeOnboarding(@Req() req: any, @Body() dto: ProviderOnboardingDto) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });

    if (!user) throw new BadRequestException('User not found');

    // 1. Update personal details on User
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        ...(dto.name ? { name: dto.name } : {}),
        ...(dto.email !== undefined ? { email: dto.email } : {}),
        ...(dto.profilePhoto !== undefined ? { profilePhoto: dto.profilePhoto } : {}),
      },
    });

    // 2. Update professional details on ProviderProfile
    let providerProfile = user.providerProfile;
    if (!providerProfile) {
      providerProfile = await this.prisma.providerProfile.create({
        data: {
          userId: user.id,
          verificationStatus: 'DRAFT',
        },
      });
    }

    const currentStatus = providerProfile.verificationStatus as string;
    const shouldKeepStatus = currentStatus === 'APPROVED' || currentStatus === 'UNDER_REVIEW' || currentStatus === 'SUBMITTED';

    await this.prisma.providerProfile.update({
      where: { id: providerProfile.id },
      data: {
        ...(dto.bio !== undefined ? { bio: dto.bio } : {}),
        ...(dto.yearsExperience !== undefined ? { yearsExperience: dto.yearsExperience } : {}),
        ...(dto.serviceRadiusKm !== undefined ? { serviceRadiusKm: dto.serviceRadiusKm } : {}),
        ...(dto.skills !== undefined ? { skills: dto.skills } : {}),
        ...(dto.addressCity !== undefined ? { addressCity: dto.addressCity } : {}),
        ...(dto.emergencyContact !== undefined ? { emergencyContact: dto.emergencyContact } : {}),
        ...(dto.dateOfBirth ? { dateOfBirth: new Date(dto.dateOfBirth) } : {}),
        ...(!shouldKeepStatus ? { verificationStatus: 'DRAFT' as any } : {}),
      },
    });

    // 3. Upsert services
    if (dto.services && Array.isArray(dto.services)) {
      for (const s of dto.services) {
        await this.prisma.providerService.upsert({
          where: {
            providerId_serviceType: {
              providerId: providerProfile.id,
              serviceType: s.serviceType,
            },
          },
          create: {
            providerId: providerProfile.id,
            serviceType: s.serviceType,
            priceInr: s.priceInr,
            durationMin: s.durationMin ?? 60,
          },
          update: {
            priceInr: s.priceInr,
            durationMin: s.durationMin ?? 60,
          },
        });
      }
    }

    return this.prisma.user.findUnique({
      where: { id: user.id },
      include: {
        providerProfile: {
          include: {
            servicesOffered: true,
            documents: true,
          },
        },
      },
    });
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('documents')
  async addDocument(@Req() req: any, @Body() dto: AddDocumentDto) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });

    if (!user || !user.providerProfile) {
      throw new BadRequestException('Provider profile not found');
    }

    const doc = await this.prisma.providerDocument.create({
      data: {
        providerId: user.providerProfile.id,
        documentType: dto.documentType,
        title: dto.title,
        issuingOrg: dto.issuingOrg,
        documentUrl: dto.documentUrl,
        issueDate: dto.issueDate ? new Date(dto.issueDate) : undefined,
        expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : undefined,
        status: 'PENDING',
      },
    });

    if (dto.documentType === 'GOVT_ID') {
      await this.prisma.providerProfile.update({
        where: { id: user.providerProfile.id },
        data: { idDocumentUrl: dto.documentUrl },
      });
    }

    return doc;
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('documents/:id')
  async deleteDocument(@Req() req: any, @Param('id') docId: string) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });

    return this.prisma.providerDocument.deleteMany({
      where: { id: docId, providerId: user!.providerProfile!.id },
    });
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('submit-verification')
  async submitVerification(@Req() req: any) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: {
        providerProfile: {
          include: { documents: true, servicesOffered: true },
        },
      },
    });

    if (!user || !user.providerProfile) {
      throw new BadRequestException('Provider profile not found');
    }

    const p = user.providerProfile;
    if (p.documents.length === 0) {
      throw new BadRequestException('Please upload at least one government ID before submitting for verification.');
    }

    return this.prisma.providerProfile.update({
      where: { id: p.id },
      data: {
        verificationStatus: 'SUBMITTED' as any,
        rejectionReason: null,
      },
      include: { documents: true, servicesOffered: true },
    });
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('profile')
  async updateProfile(@Req() req: any, @Body() dto: ProviderOnboardingDto) {
    return this.completeOnboarding(req, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('availability')
  async setAvailability(@Req() req: any, @Body() dto: SetAvailabilityDto) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });

    const status = user?.providerProfile?.verificationStatus as string;
    if (dto.isAvailable && status !== 'APPROVED' && status !== 'VERIFIED') {
      throw new BadRequestException(
        `Only verified and approved providers can go online. Current status: ${status}`,
      );
    }

    return this.prisma.providerProfile.update({
      where: { id: user!.providerProfile!.id },
      data: {
        isAvailable: dto.isAvailable,
        currentLat: dto.lat,
        currentLng: dto.lng,
      },
    });
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('services')
  async addService(@Req() req: any, @Body() dto: AddServiceDto) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });
    return this.prisma.providerService.upsert({
      where: {
        providerId_serviceType: {
          providerId: user!.providerProfile!.id,
          serviceType: dto.serviceType,
        },
      },
      create: { ...dto, providerId: user!.providerProfile!.id },
      update: { priceInr: dto.priceInr, durationMin: dto.durationMin },
    });
  }

  // Earnings summary with today, this week, and all-time aggregates
  @UseGuards(FirebaseAuthGuard)
  @Get('earnings')
  async earnings(@Req() req: any) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });

    if (!user || !user.providerProfile) {
      return { todayInr: 0, weekInr: 0, totalInr: 0, count: 0, bookings: [] };
    }

    const bookings = await this.prisma.booking.findMany({
      where: {
        providerId: user.providerProfile.id,
        status: 'COMPLETED',
      },
      include: { payment: true, pet: true, petOwner: { include: { user: true } } },
      orderBy: { scheduledAt: 'desc' },
    });

    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekStart = new Date(now);
    weekStart.setDate(weekStart.getDate() - 7);

    let todayInr = 0;
    let weekInr = 0;
    let totalInr = 0;

    for (const b of bookings) {
      const amount = b.payment?.amountInr ?? b.priceInr ?? 0;
      totalInr += amount;
      const bDate = new Date(b.scheduledAt);
      if (bDate >= todayStart) todayInr += amount;
      if (bDate >= weekStart) weekInr += amount;
    }

    return {
      todayInr,
      weekInr,
      totalInr,
      count: bookings.length,
      bookings,
    };
  }
}

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}
