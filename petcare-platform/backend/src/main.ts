import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { initFirebaseAdmin } from './common/firebase-admin';

async function bootstrap() {
  initFirebaseAdmin();
  const app = await NestFactory.create(AppModule);
  app.enableCors({ origin: '*' }); // tighten this before production
  
  // Set the global prefix so routes match /api/...
  app.setGlobalPrefix('api');

  app.useGlobalPipes(new ValidationPipe({ transform: true }));
  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  console.log(`PetCare backend running on :${port}`);
}
bootstrap();