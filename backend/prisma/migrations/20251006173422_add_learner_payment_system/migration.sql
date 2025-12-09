/*
  Warnings:

  - A unique constraint covering the columns `[stripeCustomerId]` on the table `users` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "users" ADD COLUMN     "stripeCustomerId" TEXT;

-- CreateTable
CREATE TABLE "learner_payment_methods" (
    "id" TEXT NOT NULL,
    "userId" INTEGER NOT NULL,
    "stripePaymentMethodId" TEXT NOT NULL,
    "cardBrand" TEXT,
    "cardLast4" TEXT,
    "cardExpMonth" INTEGER,
    "cardExpYear" INTEGER,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "learner_payment_methods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ruby_purchases" (
    "id" TEXT NOT NULL,
    "userId" INTEGER NOT NULL,
    "rubiesAmount" INTEGER NOT NULL,
    "costCents" INTEGER NOT NULL,
    "stripePaymentIntentId" TEXT,
    "paymentMethodId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ruby_purchases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_rubies" (
    "id" TEXT NOT NULL,
    "userId" INTEGER NOT NULL,
    "balance" INTEGER NOT NULL DEFAULT 0,
    "totalPurchased" INTEGER NOT NULL DEFAULT 0,
    "totalSpent" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_rubies_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "learner_payment_methods_stripePaymentMethodId_key" ON "learner_payment_methods"("stripePaymentMethodId");

-- CreateIndex
CREATE INDEX "learner_payment_methods_userId_idx" ON "learner_payment_methods"("userId");

-- CreateIndex
CREATE INDEX "learner_payment_methods_stripePaymentMethodId_idx" ON "learner_payment_methods"("stripePaymentMethodId");

-- CreateIndex
CREATE UNIQUE INDEX "ruby_purchases_stripePaymentIntentId_key" ON "ruby_purchases"("stripePaymentIntentId");

-- CreateIndex
CREATE INDEX "ruby_purchases_userId_idx" ON "ruby_purchases"("userId");

-- CreateIndex
CREATE INDEX "ruby_purchases_createdAt_idx" ON "ruby_purchases"("createdAt" DESC);

-- CreateIndex
CREATE INDEX "ruby_purchases_status_idx" ON "ruby_purchases"("status");

-- CreateIndex
CREATE UNIQUE INDEX "user_rubies_userId_key" ON "user_rubies"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "users_stripeCustomerId_key" ON "users"("stripeCustomerId");

-- AddForeignKey
ALTER TABLE "learner_payment_methods" ADD CONSTRAINT "learner_payment_methods_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ruby_purchases" ADD CONSTRAINT "ruby_purchases_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ruby_purchases" ADD CONSTRAINT "ruby_purchases_paymentMethodId_fkey" FOREIGN KEY ("paymentMethodId") REFERENCES "learner_payment_methods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_rubies" ADD CONSTRAINT "user_rubies_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
