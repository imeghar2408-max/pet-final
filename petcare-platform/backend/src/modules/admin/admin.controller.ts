import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { AdminOnlyGuard } from './admin-only.guard';
import { PrismaService } from '../../common/prisma.module';
import { sendPush } from '../../common/push';
import { ComplaintStatus } from '@prisma/client';

// There is no dedicated admin app in this scaffold — these endpoints are
// meant to be driven from `npx prisma studio` (see backend README) or a
// lightweight internal tool later. The one thing that MUST happen somewhere
// is provider verification: /providers/nearby only ever returns providers
// with verificationStatus VERIFIED, so without this step (or an equivalent
// manual DB edit) no provider will ever appear to pet owners.
@UseGuards(FirebaseAuthGuard, AdminOnlyGuard)
@Controller('admin')
export class AdminController {
  constructor(private prisma: PrismaService) {}

  @Get('providers')
  async listProviders(@Query('status') status?: string) {
    const where: any = {};
    if (status && status !== 'ALL') {
      if (status === 'PENDING') {
        where.verificationStatus = { in: ['SUBMITTED', 'UNDER_REVIEW', 'PENDING'] };
      } else {
        where.verificationStatus = status;
      }
    }
    return this.prisma.providerProfile.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        user: true,
        servicesOffered: true,
        documents: { orderBy: { createdAt: 'desc' } },
      },
    });
  }

  @Get('providers/pending')
  async pendingProviders() {
    return this.prisma.providerProfile.findMany({
      where: {
        verificationStatus: { in: ['SUBMITTED', 'UNDER_REVIEW', 'PENDING'] as any },
      },
      include: {
        user: true,
        servicesOffered: true,
        documents: { orderBy: { createdAt: 'desc' } },
      },
    });
  }

  @Get('providers/:id')
  async getProviderDetail(@Param('id') id: string) {
    return this.prisma.providerProfile.findUnique({
      where: { id },
      include: {
        user: true,
        servicesOffered: true,
        documents: { orderBy: { createdAt: 'desc' } },
        bookings: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { pet: true, payment: true },
        },
      },
    });
  }

  @Post('providers/:id/approve')
  async approveProvider(@Param('id') id: string) {
    const provider = await this.prisma.providerProfile.update({
      where: { id },
      data: {
        verificationStatus: 'APPROVED' as any,
        rejectionReason: null,
        suspensionReason: null,
      },
      include: { user: true },
    });

    // Mark pending documents as approved
    await this.prisma.providerDocument.updateMany({
      where: { providerId: id, status: 'PENDING' },
      data: { status: 'APPROVED' },
    });

    await sendPush(
      provider.user.fcmToken,
      'You are Approved! 🎉',
      'Congratulations! Your PetCare provider application has been approved. You can now go online and accept bookings.',
      { type: 'PROVIDER_VERIFICATION', status: 'APPROVED' },
    );
    return provider;
  }

  @Post('providers/:id/reject')
  async rejectProvider(
    @Param('id') id: string,
    @Body() body: { reason: string },
  ) {
    const reason = body.reason || 'Document verification could not be completed with the provided information.';
    const provider = await this.prisma.providerProfile.update({
      where: { id },
      data: {
        verificationStatus: 'REJECTED' as any,
        rejectionReason: reason,
        isAvailable: false,
      },
      include: { user: true },
    });

    await sendPush(
      provider.user.fcmToken,
      'Verification Update',
      `Your verification was not approved: ${reason}. Please update your documents and resubmit.`,
      { type: 'PROVIDER_VERIFICATION', status: 'REJECTED', reason },
    );
    return provider;
  }

  @Post('providers/:id/suspend')
  async suspendProvider(
    @Param('id') id: string,
    @Body() body: { reason: string },
  ) {
    const reason = body.reason || 'Account suspended pending administrative review.';
    const provider = await this.prisma.providerProfile.update({
      where: { id },
      data: {
        verificationStatus: 'SUSPENDED' as any,
        suspensionReason: reason,
        isAvailable: false,
      },
      include: { user: true },
    });

    await sendPush(
      provider.user.fcmToken,
      'Account Suspended',
      `Your provider account has been suspended: ${reason}. Please contact PetCare support.`,
      { type: 'PROVIDER_SUSPENSION', reason },
    );
    return provider;
  }

  @Post('providers/:id/verify')
  async verifyProvider(
    @Param('id') id: string,
    @Body() body: { approve: boolean; reason?: string },
  ) {
    if (body.approve) {
      return this.approveProvider(id);
    } else {
      return this.rejectProvider(id, { reason: body.reason ?? 'Application rejected by administrator.' });
    }
  }

  @Get('bookings')
  async allBookings() {
    return this.prisma.booking.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: {
        pet: true,
        payment: true,
        petOwner: { include: { user: true } },
        provider: { include: { user: true } },
      },
    });
  }

  // Headline numbers for the dashboard landing page.
  @Get('metrics')
  async metrics() {
    const [
      totalBookings,
      pendingVerifications,
      activeProviders,
      totalOwners,
      statusCounts,
      revenue,
      openComplaints,
    ] = await Promise.all([
      this.prisma.booking.count(),
      this.prisma.providerProfile.count({ where: { verificationStatus: 'PENDING' } }),
      this.prisma.providerProfile.count({ where: { verificationStatus: 'VERIFIED' } }),
      this.prisma.petOwnerProfile.count(),
      this.prisma.booking.groupBy({ by: ['status'], _count: true }),
      this.prisma.payment.aggregate({ where: { status: 'PAID' }, _sum: { amountInr: true } }),
      this.prisma.complaint.count({ where: { status: { in: ['OPEN', 'IN_PROGRESS'] } } }),
    ]);

    return {
      totalBookings,
      pendingVerifications,
      activeProviders,
      totalOwners,
      revenueInr: revenue._sum.amountInr ?? 0,
      openComplaints,
      bookingsByStatus: Object.fromEntries(
        statusCounts.map((s) => [s.status, s._count]),
      ),
    };
  }

  // Support queue: every complaint filed from either app, newest first.
  // Optionally filtered by status (OPEN, IN_PROGRESS, RESOLVED, CLOSED).
  @Get('complaints')
  async complaints(@Query('status') status?: ComplaintStatus) {
    return this.prisma.complaint.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        reportedBy: true,
        booking: { include: { pet: true, provider: { include: { user: true } } } },
      },
    });
  }

  // Move a complaint through the queue, optionally leaving an internal note.
  // Notifies whoever filed it when it's marked RESOLVED or CLOSED.
  @Post('complaints/:id/status')
  async updateComplaintStatus(
    @Param('id') id: string,
    @Body() body: { status: ComplaintStatus; adminNote?: string },
  ) {
    const complaint = await this.prisma.complaint.update({
      where: { id },
      data: {
        status: body.status,
        adminNote: body.adminNote,
        resolvedAt: body.status === 'RESOLVED' || body.status === 'CLOSED' ? new Date() : null,
      },
      include: { reportedBy: true },
    });

    if (body.status === 'RESOLVED' || body.status === 'CLOSED') {
      await sendPush(
        complaint.reportedBy.fcmToken,
        'Your report has been reviewed',
        body.adminNote || `Your report "${complaint.subject}" has been ${body.status.toLowerCase()}.`,
        { type: 'COMPLAINT_UPDATE', complaintId: complaint.id },
      );
    }

    return complaint;
  }
}
