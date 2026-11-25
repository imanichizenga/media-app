import {
  Cpu,
  Earth,
  Globe,
  GraduationCap,
  HeartPulse,
  type Icon,
  Landmark,
  Leaf,
  MessageSquareQuote,
  Music,
  Newspaper,
  TrendingUp,
  Trophy,
} from "@news/ui/icons";

/** The names the admin offers (and the app draws). */
export const CATEGORY_ICONS: Record<string, Icon> = {
  newspaper: Newspaper,
  landmark: Landmark,
  "trending-up": TrendingUp,
  trophy: Trophy,
  "heart-pulse": HeartPulse,
  "graduation-cap": GraduationCap,
  cpu: Cpu,
  music: Music,
  leaf: Leaf,
  globe: Globe,
  earth: Earth,
  "message-square-quote": MessageSquareQuote,
};
