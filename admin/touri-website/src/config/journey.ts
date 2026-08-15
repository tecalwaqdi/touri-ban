import type { ComponentType, SVGProps } from "react";
import {
  IconBell,
  IconCar,
  IconCard,
  IconChat,
  IconCheck,
  IconCompass,
  IconPin,
  IconRoute,
  IconSpark,
  IconUser,
} from "@/components/icons";

export type JourneyKind = "customer" | "driver";

type IconType = ComponentType<SVGProps<SVGSVGElement> & { size?: number }>;

export type JourneyVisual = {
  icon: IconType;
};

export const customerVisuals: readonly JourneyVisual[] = [
  { icon: IconSpark },
  { icon: IconPin },
  { icon: IconCar },
  { icon: IconCheck },
  { icon: IconCard },
  { icon: IconUser },
  { icon: IconRoute },
];

export const driverVisuals: readonly JourneyVisual[] = [
  { icon: IconUser },
  { icon: IconSpark },
  { icon: IconBell },
  { icon: IconCompass },
  { icon: IconCheck },
  { icon: IconChat },
  { icon: IconCar },
];

export function journeyVisuals(kind: JourneyKind) {
  return kind === "driver" ? driverVisuals : customerVisuals;
}
