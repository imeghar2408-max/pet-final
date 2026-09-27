import { Global, Module, Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

// MOCKED — in-memory fallback if DATABASE_URL is not connected
const noOp = {
  findMany: async () => [],
  findFirst: async () => null,
  findUnique: async () => null,
  count: async () => 0,
  groupBy: async () => [],
  aggregate: async () => ({ _sum: { amountInr: 0 } }),
  create: async (d: { data?: Record<string, unknown> }) => d?.data ?? {},
  update: async (d: { data?: Record<string, unknown> }) => d?.data ?? {},
  delete: async () => ({}),
};

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    super();
    if (!process.env.DATABASE_URL) {
      console.warn('[AI Studio] Database not connected — using mock');
      return new Proxy(this, {
        get: (target, prop, receiver) => {
          if (prop in target) {
            return Reflect.get(target, prop, receiver);
          }
          return noOp;
        },
      });
    }
  }

  async onModuleInit() {
    if (!process.env.DATABASE_URL) return;
    try {
      await this.$connect();
    } catch {
      console.warn('[AI Studio] Database connection failed — continuing with mock');
    }
  }

  async onModuleDestroy() {
    if (!process.env.DATABASE_URL) return;
    try {
      await this.$disconnect();
    } catch {
      // ignore disconnect errors
    }
  }
}

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
