import dayjs from "npm:dayjs@1.11.13";
import utc from "npm:dayjs@1.11.13/plugin/utc.js";
import timezone from "npm:dayjs@1.11.13/plugin/timezone.js";
import isoWeek from "npm:dayjs@1.11.13/plugin/isoWeek.js";
import { BOSSES, MAX_PLAYER_TYPE, IGNORE_PLAYER_TYPES } from "../constants.ts";

dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(isoWeek);
dayjs.tz.setDefault("Asia/Seoul");

export const day = dayjs;

export function getRandomBoss(): string {
    const randomIndex = Math.floor(Math.random() * BOSSES.length);
    return BOSSES[randomIndex];
}

export function getRandomCharacter(): number {
    let randomCharacter = Math.floor(Math.random() * (MAX_PLAYER_TYPE + 1));

    while (IGNORE_PLAYER_TYPES.includes(randomCharacter)) {
        randomCharacter = Math.floor(Math.random() * (MAX_PLAYER_TYPE + 1));
    }

    return randomCharacter;
}

export function validateSeed(seed: string): boolean {
    const allowedCharacters = "ABCDEFGHJKLMNPQRSTWXYZ01234V6789";

    if (seed.length !== 8) {
        return false;
    }

    for (const char of seed) {
        if (!allowedCharacters.includes(char)) {
            return false;
        }
    }

    return true;
}

// https://www.reddit.com/r/bindingofisaac/comments/2wvp6h/comment/csdppvx/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
function getChecksum(seed: number): number {
    let checksum = 0;

    while (true) {
        checksum = (checksum + (seed & 0xFF)) & 0xFF;
        checksum = (2 * checksum + (checksum >>> 7)) & 0xFF;
        seed = seed >>> 5;
        if (seed === 0) break;
    }

    return checksum;
}

export function generateSeed(): string {
    const randomSeed = Math.floor(Math.random() * 0xFFFFFFFF);

    const checksum = getChecksum(randomSeed);

    const combined = ((BigInt(randomSeed) ^ 0xFEF7FFDn) << 8n) |
        BigInt(checksum);

    const lookupTable = "ABCDEFGHJKLMNPQRSTWXYZ01234V6789";
    const result: string[] = [];
    for (let i = 0; i < 8; i++) {
        const charIndex = (combined >> BigInt(35 - i * 5)) & 0x1Fn;
        result.push(lookupTable[Number(charIndex)]);
    }

    return result.join("");
}

export function getTodayString(): string {
    return day().tz().format("YYYY-MM-DD");
}
