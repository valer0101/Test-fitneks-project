-- CreateEnum
CREATE TYPE "EventType" AS ENUM ('CLASS', 'CHALLENGE');

-- CreateEnum
CREATE TYPE "EventStatus" AS ENUM ('UPCOMING', 'COMPLETED');

-- CreateTable
CREATE TABLE "events" (
    "id" TEXT NOT NULL,
    "trainerId" INTEGER NOT NULL,
    "type" "EventType" NOT NULL,
    "status" "EventStatus" NOT NULL,
    "title" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "maxParticipants" INTEGER,
    "ticketValue" DOUBLE PRECISION,
    "giftsReceived" DOUBLE PRECISION,
    "xpEarned" INTEGER,
    "equipment" TEXT[],
    "trainingType" TEXT NOT NULL,
    "pointsBreakdown" JSONB,
    "duration" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "events_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "events" ADD CONSTRAINT "events_trainerId_fkey" FOREIGN KEY ("trainerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
