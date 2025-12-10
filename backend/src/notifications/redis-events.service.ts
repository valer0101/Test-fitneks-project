import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisEventsService implements OnModuleInit, OnModuleDestroy {
  private publisher: Redis;
  private subscriber: Redis;
  private handlers = new Map<string, Function[]>();

  constructor(private configService: ConfigService) {
    const host = this.configService.get('REDIS_HOST') || 'localhost';
    const port = this.configService.get('REDIS_PORT') || 6379;

    this.publisher = new Redis({ host, port });
    this.subscriber = new Redis({ host, port });

    console.log(`🔗 Redis connections created: ${host}:${port}`);
  }

  async onModuleInit() {
    this.subscriber.on('message', (channel, message) => {
      const handlers = this.handlers.get(channel) || [];
      const payload = JSON.parse(message);
      
      console.log(`📨 Received Redis event: ${channel}`, payload);
      handlers.forEach(handler => handler(payload));
    });

    console.log('✅ RedisEventsService initialized');
  }

  async onModuleDestroy() {
    await this.publisher.quit();
    await this.subscriber.quit();
    console.log('👋 Redis connections closed');
  }

  // Publish an event to Redis
  async emit(event: string, payload: any): Promise<void> {
    await this.publisher.publish(event, JSON.stringify(payload));
    console.log(`📡 Published Redis event: ${event}`, payload);
  }

  // Subscribe to an event from Redis
  async on(event: string, handler: Function): Promise<void> {
    if (!this.handlers.has(event)) {
      this.handlers.set(event, []);
      await this.subscriber.subscribe(event);
      console.log(`👂 Subscribed to Redis event: ${event}`);
    }
    
    this.handlers.get(event)!.push(handler);
  }
}