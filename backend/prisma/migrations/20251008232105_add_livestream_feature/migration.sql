-- CreateEnum
CREATE TYPE "LiveStreamStatus" AS ENUM ('SCHEDULED', 'LIVE', 'ENDED', 'CANCELED');

-- CreateEnum
CREATE TYPE "LiveStreamVisibility" AS ENUM ('PUBLIC', 'PRIVATE');

-- CreateEnum
CREATE TYPE "Equipment" AS ENUM ('DUMBBELLS', 'KETTLEBELL', 'PLATES', 'YOGA_BLOCK', 'YOGA_MAT', 'RESISTANCE_BAND', 'PULL_UP_BAR', 'NO_EQUIPMENT');

-- CreateEnum
CREATE TYPE "WorkoutStyle" AS ENUM ('WEIGHTS', 'CALISTHENICS', 'RESISTANCE', 'YOGA', 'PILATES', 'MOBILITY');

-- CreateTable
CREATE TABLE "live_streams" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "title" VARCHAR(50) NOT NULL,
    "description" VARCHAR(200) NOT NULL,
    "status" "LiveStreamStatus" NOT NULL DEFAULT 'SCHEDULED',
    "visibility" "LiveStreamVisibility" NOT NULL DEFAULT 'PUBLIC',
    "scheduledAt" TIMESTAMP(3) NOT NULL,
    "maxParticipants" INTEGER NOT NULL,
    "isRecurring" BOOLEAN NOT NULL DEFAULT false,
    "equipmentNeeded" "Equipment"[],
    "workoutStyle" "WorkoutStyle" NOT NULL,
    "giftRequirement" INTEGER NOT NULL DEFAULT 0,
    "musclePoints" JSONB NOT NULL,
    "totalPossiblePoints" INTEGER NOT NULL,
    "trainerId" INTEGER NOT NULL,
    "parentStreamId" TEXT,
    "eventId" TEXT,

    CONSTRAINT "live_streams_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stream_participations" (
    "id" TEXT NOT NULL,
    "userId" INTEGER NOT NULL,
    "liveStreamId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt" TIMESTAMP(3),
    "participationPct" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "armsEarned" INTEGER NOT NULL DEFAULT 0,
    "chestEarned" INTEGER NOT NULL DEFAULT 0,
    "backEarned" INTEGER NOT NULL DEFAULT 0,
    "absEarned" INTEGER NOT NULL DEFAULT 0,
    "legsEarned" INTEGER NOT NULL DEFAULT 0,
    "totalEarned" INTEGER NOT NULL DEFAULT 0,
    "pointsCredited" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "stream_participations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "live_streams_eventId_key" ON "live_streams"("eventId");

-- CreateIndex
CREATE INDEX "live_streams_trainerId_idx" ON "live_streams"("trainerId");

-- CreateIndex
CREATE INDEX "live_streams_scheduledAt_idx" ON "live_streams"("scheduledAt");

-- CreateIndex
CREATE INDEX "live_streams_status_idx" ON "live_streams"("status");

-- CreateIndex
CREATE INDEX "stream_participations_userId_idx" ON "stream_participations"("userId");

-- CreateIndex
CREATE INDEX "stream_participations_liveStreamId_idx" ON "stream_participations"("liveStreamId");

-- CreateIndex
CREATE UNIQUE INDEX "stream_participations_userId_liveStreamId_key" ON "stream_participations"("userId", "liveStreamId");

-- AddForeignKey
ALTER TABLE "live_streams" ADD CONSTRAINT "live_streams_trainerId_fkey" FOREIGN KEY ("trainerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_streams" ADD CONSTRAINT "live_streams_parentStreamId_fkey" FOREIGN KEY ("parentStreamId") REFERENCES "live_streams"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_streams" ADD CONSTRAINT "live_streams_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "events"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stream_participations" ADD CONSTRAINT "stream_participations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stream_participations" ADD CONSTRAINT "stream_participations_liveStreamId_fkey" FOREIGN KEY ("liveStreamId") REFERENCES "live_streams"("id") ON DELETE CASCADE ON UPDATE CASCADE;
