-- CreateEnum
CREATE TYPE "GiftType" AS ENUM ('PROTEIN', 'PROTEIN_SHAKE', 'PROTEIN_BAR');

-- CreateEnum
CREATE TYPE "CurrencyType" AS ENUM ('TOKENS', 'RUBIES');

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "fitneksTokens" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "protein" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "gift_purchases" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" INTEGER NOT NULL,
    "giftType" "GiftType" NOT NULL,
    "quantity" INTEGER NOT NULL,
    "currencyUsed" "CurrencyType" NOT NULL,
    "cost" INTEGER NOT NULL,

    CONSTRAINT "gift_purchases_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "gift_purchases_userId_createdAt_idx" ON "gift_purchases"("userId", "createdAt");

-- AddForeignKey
ALTER TABLE "gift_purchases" ADD CONSTRAINT "gift_purchases_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
