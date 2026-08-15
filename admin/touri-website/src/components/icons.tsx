import type { ReactNode, SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function Base({ size = 24, children, ...props }: IconProps & { children: ReactNode }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...props}
    >
      {children}
    </svg>
  );
}

export function IconPin(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M12 21s7-5.4 7-11a7 7 0 1 0-14 0c0 5.6 7 11 7 11Z" />
      <circle cx="12" cy="10" r="2.2" />
    </Base>
  );
}

export function IconCar(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M3 13h18l-1.4-4.2A3 3 0 0 0 16.7 7H7.3a3 3 0 0 0-2.9 1.8L3 13Z" />
      <path d="M5 17h.01M19 17h.01M7 17a2 2 0 1 1-4 0 2 2 0 0 1 4 0Zm14 0a2 2 0 1 1-4 0 2 2 0 0 1 4 0Z" />
    </Base>
  );
}

export function IconWallet(props: IconProps) {
  return (
    <Base {...props}>
      <rect x="3" y="6" width="18" height="13" rx="2.5" />
      <path d="M3 10h18" />
      <circle cx="16.5" cy="14.5" r="1" fill="currentColor" />
    </Base>
  );
}

export function IconChat(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M4.5 18.5 6 16a8 8 0 1 1 3 2.4L4.5 18.5Z" />
    </Base>
  );
}

export function IconBell(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M6 9a6 6 0 1 1 12 0c0 7 3 7 3 9H3c0-2 3-2 3-9Z" />
      <path d="M10 21a2 2 0 0 0 4 0" />
    </Base>
  );
}

export function IconShield(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M12 3 5 6v6c0 4.5 3 7.5 7 9 4-1.5 7-4.5 7-9V6l-7-3Z" />
      <path d="m9 12 2 2 4-4" />
    </Base>
  );
}

export function IconCard(props: IconProps) {
  return (
    <Base {...props}>
      <rect x="3" y="6" width="18" height="12" rx="2" />
      <path d="M3 10h18M7 15h4" />
    </Base>
  );
}

export function IconCash(props: IconProps) {
  return (
    <Base {...props}>
      <rect x="3" y="7" width="18" height="10" rx="2" />
      <circle cx="12" cy="12" r="2.2" />
    </Base>
  );
}

export function IconRoute(props: IconProps) {
  return (
    <Base {...props}>
      <circle cx="6" cy="6" r="2" />
      <circle cx="18" cy="18" r="2" />
      <path d="M8 7c4 0 4 4 8 4s4 4 0 6" />
    </Base>
  );
}

export function IconGlobe(props: IconProps) {
  return (
    <Base {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="M3 12h18M12 3c3 3.5 3 14.5 0 18M12 3c-3 3.5-3 14.5 0 18" />
    </Base>
  );
}

export function IconSpark(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M12 3v4M12 17v4M4.9 4.9l2.8 2.8M16.3 16.3l2.8 2.8M3 12h4M17 12h4M4.9 19.1l2.8-2.8M16.3 7.7l2.8-2.8" />
    </Base>
  );
}

export function IconUser(props: IconProps) {
  return (
    <Base {...props}>
      <circle cx="12" cy="8" r="3.2" />
      <path d="M5 19c1.5-3 4-4.5 7-4.5S17.5 16 19 19" />
    </Base>
  );
}

export function IconCheck(props: IconProps) {
  return (
    <Base {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="m8.5 12 2.4 2.4 4.6-5" />
    </Base>
  );
}

export function IconLock(props: IconProps) {
  return (
    <Base {...props}>
      <rect x="5" y="11" width="14" height="10" rx="2" />
      <path d="M8 11V8a4 4 0 0 1 8 0v3" />
    </Base>
  );
}

export function IconCompass(props: IconProps) {
  return (
    <Base {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="m9.2 14.8 1.4-5.2 5.2-1.4-1.4 5.2-5.2 1.4Z" />
    </Base>
  );
}

export function IconMenu(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M4 7h16M4 12h16M4 17h16" />
    </Base>
  );
}

export function IconClose(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M6 6l12 12M18 6 6 18" />
    </Base>
  );
}

export function IconSun(props: IconProps) {
  return (
    <Base {...props}>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 3v2M12 19v2M4.9 4.9l1.5 1.5M17.6 17.6l1.5 1.5M3 12h2M19 12h2M4.9 19.1l1.5-1.5M17.6 6.4l1.5-1.5" />
    </Base>
  );
}

export function IconMoon(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M16 3a8 8 0 1 0 5 13 7 7 0 0 1-5-13Z" />
    </Base>
  );
}

export function IconChevron(props: IconProps) {
  return (
    <Base {...props}>
      <path d="m6 9 6 6 6-6" />
    </Base>
  );
}

export function IconMail(props: IconProps) {
  return (
    <Base {...props}>
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <path d="m4 7 8 6 8-6" />
    </Base>
  );
}

export function IconPhone(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M7 3h4l1.5 4-2.2 1.3a12 12 0 0 0 5.4 5.4L17 11.5 21 13v4a2 2 0 0 1-2.2 2 16 16 0 0 1-13.6-13.6A2 2 0 0 1 7 3Z" />
    </Base>
  );
}

export function IconWhatsApp(props: IconProps) {
  return (
    <Base {...props}>
      <path d="M5 19.5 6.4 16A8 8 0 1 1 8 18.2L5 19.5Z" />
      <path d="M9 10c.2 2 2 4 4 5l1.4-.7.8.3-.4 1.3A7 7 0 0 1 9 10Z" />
    </Base>
  );
}

export const featureIcons = [
  IconSpark,
  IconLock,
  IconRoute,
  IconBell,
  IconChat,
  IconCheck,
  IconWallet,
  IconGlobe,
  IconCompass,
  IconPin,
];

export const customerIcons = [
  IconCar,
  IconPin,
  IconRoute,
  IconCheck,
  IconChat,
  IconCard,
  IconCash,
  IconCheck,
  IconCard,
  IconCompass,
];

export const driverIcons = [
  IconBell,
  IconCheck,
  IconRoute,
  IconCar,
  IconWallet,
  IconCard,
  IconBell,
  IconChat,
  IconUser,
  IconSpark,
];

export const paymentIcons = [IconCard, IconCash, IconShield, IconLock, IconCheck];
export const safetyIcons = [IconUser, IconRoute, IconPin, IconChat, IconShield, IconCheck];
