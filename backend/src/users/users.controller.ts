import { Controller, Get, UseGuards, Req } from '@nestjs/common';
import { UsersService } from './users.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { Public } from '../common/decorators/public.decorator.js';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('profile')
  async getProfile(@Req() req: any) {
    return this.usersService.getProfile(req.user.sub);
  }

  @Public()
  @Get('leaderboard')
  async getLeaderboard() {
    return this.usersService.getLeaderboard();
  }
}
