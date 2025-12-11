-- CreateTable
CREATE TABLE "banned_stream_participants" (
    "id" TEXT NOT NULL,
    "livestreamId" TEXT NOT NULL,
    "userId" INTEGER NOT NULL,
    "participantSid" TEXT NOT NULL,
    "bannedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "bannedBy" INTEGER NOT NULL,
    "reason" TEXT,

    CONSTRAINT "banned_stream_participants_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "banned_stream_participants_livestreamId_idx" ON "banned_stream_participants"("livestreamId");

-- CreateIndex
CREATE INDEX "banned_stream_participants_userId_idx" ON "banned_stream_participants"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "banned_stream_participants_livestreamId_userId_key" ON "banned_stream_participants"("livestreamId", "userId");

-- AddForeignKey
ALTER TABLE "banned_stream_participants" ADD CONSTRAINT "banned_stream_participants_livestreamId_fkey" FOREIGN KEY ("livestreamId") REFERENCES "live_streams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "banned_stream_participants" ADD CONSTRAINT "banned_stream_participants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "banned_stream_participants" ADD CONSTRAINT "banned_stream_participants_bannedBy_fkey" FOREIGN KEY ("bannedBy") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
