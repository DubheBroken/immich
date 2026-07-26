import { Injectable } from '@nestjs/common';
import { AuthDto } from 'src/dtos/auth.dto';
import { MapMarkerDto, MapMarkerResponseDto, MapReverseGeocodeDto } from 'src/dtos/map.dto';
import { BaseService } from 'src/services/base.service';
import { getMyPartnerIds } from 'src/utils/asset.util';

/**
 * Parse the first language tag from an Accept-Language header value.
 * e.g. "zh-CN,zh;q=0.9,en;q=0.8" -> "zh"
 */
const parseAcceptLanguage = (header?: string): string | undefined => {
  if (!header) {
    return undefined;
  }
  const tag = header.split(',')[0]?.trim();
  if (!tag) {
    return undefined;
  }
  return tag.split('-')[0]?.split(';')[0] || undefined;
};

@Injectable()
export class MapService extends BaseService {
  async getMapMarkers(auth: AuthDto, options: MapMarkerDto): Promise<MapMarkerResponseDto[]> {
    const userIds = [auth.user.id];
    if (options.withPartners) {
      const partnerIds = await getMyPartnerIds({ userId: auth.user.id, repository: this.partnerRepository });
      userIds.push(...partnerIds);
    }

    const albumIds = options.withSharedAlbums ? await this.albumRepository.getAllIds(auth.user.id) : [];

    return this.mapRepository.getMapMarkers(auth.user.id, userIds, albumIds, options);
  }

  async reverseGeocode(dto: MapReverseGeocodeDto, acceptLanguage?: string) {
    const { lat: latitude, lon: longitude } = dto;
    // Query param "language" takes precedence, then Accept-Language header, then default 'en'
    const language = dto.language || parseAcceptLanguage(acceptLanguage);
    // eventually this should probably return an array of results
    const result = await this.mapRepository.reverseGeocode({ latitude, longitude, language });
    return result ? [result] : [];
  }
}
