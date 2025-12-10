-- AlterTable
ALTER TABLE "live_streams" ADD COLUMN     "endedAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "ruby_transfers" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "senderId" INTEGER NOT NULL,
    "receiverId" INTEGER NOT NULL,
    "livestreamId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,

    CONSTRAINT "ruby_transfers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stream_reviews" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" INTEGER NOT NULL,
    "livestreamId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "feedback" TEXT,

    CONSTRAINT "stream_reviews_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ruby_transfers_senderId_idx" ON "ruby_transfers"("senderId");

-- CreateIndex
CREATE INDEX "ruby_transfers_receiverId_idx" ON "ruby_transfers"("receiverId");

-- CreateIndex
CREATE INDEX "ruby_transfers_livestreamId_idx" ON "ruby_transfers"("livestreamId");

-- CreateIndex
CREATE INDEX "stream_reviews_livestreamId_idx" ON "stream_reviews"("livestreamId");

-- CreateIndex
CREATE UNIQUE INDEX "stream_reviews_userId_livestreamId_key" ON "stream_reviews"("userId", "livestreamId");

-- AddForeignKey
ALTER TABLE "ruby_transfers" ADD CONSTRAINT "ruby_transfers_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ruby_transfers" ADD CONSTRAINT "ruby_transfers_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stream_reviews" ADD CONSTRAINT "stream_reviews_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
