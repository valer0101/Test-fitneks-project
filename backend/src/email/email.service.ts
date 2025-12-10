// backend/src/email/email.service.ts

import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EmailService {
  private transporter: nodemailer.Transporter;

  constructor(private configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.getOrThrow('SMTP_HOST'),
      port: +this.configService.getOrThrow('SMTP_PORT'), // The '+' converts the string to a number
      secure: this.configService.getOrThrow('SMTP_SECURE') === 'true', // Converts string to boolean
      auth: {
        user: this.configService.getOrThrow('SMTP_USER'),
        pass: this.configService.getOrThrow('SMTP_PASS'),
      },
    });
  }

  async sendPasswordResetEmail(email: string, resetLink: string) {
    const mailOptions = {
      from: '"Fitneks Support" <support@fitneks.app>',
      to: email,
      subject: 'Reset Your Fitneks Password',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body {
              font-family: Arial, sans-serif;
              background-color: #f4f4f4;
              margin: 0;
              padding: 0;
            }
            .container {
              max-width: 600px;
              margin: 0 auto;
              background-color: #ffffff;
              padding: 40px;
            }
            .header {
              text-align: center;
              margin-bottom: 30px;
            }
            .logo {
              font-size: 32px;
              font-weight: bold;
              color: #FF6B35;
              letter-spacing: 2px;
            }
            .content {
              color: #333;
              line-height: 1.6;
            }
            .button {
              display: inline-block;
              background-color: #FF6B35;
              color: #ffffff;
              padding: 15px 30px;
              text-decoration: none;
              border-radius: 5px;
              margin: 20px 0;
              text-align: center;
            }
            .footer {
              margin-top: 30px;
              padding-top: 20px;
              border-top: 1px solid #eee;
              text-align: center;
              color: #666;
              font-size: 12px;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1 class="logo">FITNEKS</h1>
            </div>
            <div class="content">
              <h2>Reset Your Password</h2>
              <p>Hi there,</p>
              <p>We received a request to reset your password for your Fitneks account. Click the button below to create a new password:</p>
              <div style="text-align: center;">
                <a href="${resetLink}" class="button">Reset Password</a>
              </div>
              <p>This link will expire in 1 hour for security reasons.</p>
              <p>If you didn't request this password reset, you can safely ignore this email. Your password will not be changed.</p>
              <p>Best regards,<br>The Fitneks Team</p>
            </div>
            <div class="footer">
              <p>© 2024 Fitneks. All rights reserved.</p>
              <p>If the button doesn't work, copy and paste this link into your browser:<br>
              <a href="${resetLink}">${resetLink}</a></p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    await this.transporter.sendMail(mailOptions);
  }
}