-- CreateTable
CREATE TABLE "livestream_gifts" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "senderId" INTEGER NOT NULL,
    "livestreamId" TEXT NOT NULL,
    "giftType" "GiftType" NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "livestream_gifts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "livestream_gifts_senderId_livestreamId_idx" ON "livestream_gifts"("senderId", "livestreamId");

-- CreateIndex
CREATE INDEX "livestream_gifts_livestreamId_createdAt_idx" ON "livestream_gifts"("livestreamId", "createdAt");

-- AddForeignKey
ALTER TABLE "livestream_gifts" ADD CONSTRAINT "livestream_gifts_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "livestream_gifts" ADD CONSTRAINT "livestream_gifts_livestreamId_fkey" FOREIGN KEY ("livestreamId") REFERENCES "live_streams"("id") ON DELETE CASCADE ON UPDATE CASCADE;
