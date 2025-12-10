-- CreateEnum
CREATE TYPE "LiveStatus" AS ENUM ('LIVE', 'OFFLINE');

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "aboutMe" TEXT,
ADD COLUMN     "isPublic" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "liveStatus" "LiveStatus" NOT NULL DEFAULT 'OFFLINE';
