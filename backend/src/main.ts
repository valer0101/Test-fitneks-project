import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import * as bodyParser from 'body-parser';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    rawBody: true, // ✅ Enable raw body globally
  });

app.enableCors({
    origin: '*',  // Allow all origins (for development)
  });

  // ✅ Use raw body ONLY for webhook endpoint (updated path)
  app.use(
    '/api/payment/webhook', // ✅ Changed from /webhooks/stripe
    bodyParser.raw({ type: 'application/json' })
  );

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );


  console.log('LiveKit API Key:', process.env.LIVEKIT_API_KEY);
console.log('LiveKit Secret:', process.env.LIVEKIT_SECRET?.substring(0, 10) + '...');



  await app.listen(3000, '0.0.0.0');  // ✅ Listen on all interfaces
  console.log(`Application is running on: http://localhost:3000`);
}
bootstrap();