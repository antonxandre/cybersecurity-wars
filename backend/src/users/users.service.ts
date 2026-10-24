import { Injectable, NotFoundException } from '@nestjs/common';
import { AuthService } from '../auth/auth.service.js';

@Injectable()
export class UsersService {
  constructor(private readonly authService: AuthService) {}

  async getProfile(userId: number) {
    const user = await this.authService.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return this.authService.sanitizeUser(user);
  }

  async getLeaderboard() {
    // Return sample leaderboard ranking of CTF players
    return [
      { rank: 1, username: 'pyromancer_red', role: 'RED_TEAM', score: 2850, flagsCaptured: 14 },
      { rank: 2, username: 'architect_blue', role: 'BLUE_TEAM', score: 2720, attacksNeutralized: 19 },
      { rank: 3, username: 'illusionist_shadow', role: 'RED_TEAM', score: 2410, flagsCaptured: 11 },
      { rank: 4, username: 'priest_sentinel', role: 'BLUE_TEAM', score: 2350, attacksNeutralized: 16 },
    ];
  }
}
