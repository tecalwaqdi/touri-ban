"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { ComponentType, ReactNode, SVGProps } from "react";
import type { Dictionary } from "@/i18n/get-dictionary";
import { customerIcons, driverIcons } from "@/components/icons";
import { AppFeatureTile } from "@/components/ui/AppFeatureTile";
import { DownloadOpenButton } from "@/components/ui/DownloadChooser";
import { PhoneMockup } from "@/components/ui/PhoneMockup";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { cn } from "@/lib/utils";

type Props = {
  dict: Dictionary;
};

type Point = {
  title: string;
  text: string;
};

type IconType = ComponentType<SVGProps<SVGSVGElement> & { size?: number }>;

const listVariants = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.045 },
  },
};

export function CustomerShowcase({ dict }: Props) {
  return (
    <AppShowcase
      id="customer"
      tone="customer"
      eyebrow={dict.customer.eyebrow}
      title={dict.customer.title}
      subtitle={dict.customer.subtitle}
      points={dict.customer.points}
      icons={customerIcons}
      dict={dict}
      phone={
        <PhoneMockup
          float="slow"
          size="md"
          src="/images/screenshots/customer/explore-abha.png"
          alt={dict.customer.title}
        />
      }
    />
  );
}

export function DriverShowcase({ dict }: Props) {
  return (
    <AppShowcase
      id="driver"
      tone="driver"
      eyebrow={dict.driver.eyebrow}
      title={dict.driver.title}
      subtitle={dict.driver.subtitle}
      points={dict.driver.points}
      icons={driverIcons}
      dict={dict}
      phone={
        <PhoneMockup
          float="slower"
          size="md"
          src="/images/screenshots/driver/new-trip-request.png"
          alt={dict.driver.title}
        />
      }
    />
  );
}

function AppShowcase({
  id,
  tone,
  eyebrow,
  title,
  subtitle,
  points,
  icons,
  dict,
  phone,
}: {
  id: "customer" | "driver";
  tone: "customer" | "driver";
  eyebrow: string;
  title: string;
  subtitle: string;
  points: readonly Point[];
  icons: readonly IconType[];
  dict: Dictionary;
  phone: ReactNode;
}) {
  const reduce = useReducedMotion();
  const driver = tone === "driver";
  const mid = Math.ceil(points.length / 2);
  const startPoints = points.slice(0, mid);
  const endPoints = points.slice(mid);

  return (
    <section
      id={id}
      className={cn(
        "overflow-x-clip px-4 py-12 sm:px-6 sm:py-16",
        driver && "bg-surface-muted",
      )}
    >
      <div className="mx-auto max-w-6xl">
        <SectionTitle eyebrow={eyebrow} title={title} subtitle={subtitle} align="center" />

        <div className="mt-7 grid items-center gap-5 sm:mt-8 lg:grid-cols-[1fr_auto_1fr] lg:gap-6">
          <FeatureColumn
            points={startPoints}
            icons={icons}
            offset={0}
            tone={tone}
            className="hidden lg:grid"
          />

          <motion.div
            className="relative order-first mx-auto w-full max-w-[14rem] sm:max-w-none lg:order-none"
            initial={reduce ? false : { opacity: 0, y: 18 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1] }}
          >
            <div
              className="pointer-events-none absolute inset-[12%] rounded-full blur-3xl"
              style={{
                background: driver ? "var(--hero-red)" : "var(--hero-glow)",
              }}
            />
            <div className="relative">{phone}</div>
          </motion.div>

          <FeatureColumn
            points={endPoints}
            icons={icons}
            offset={mid}
            tone={tone}
            className="hidden lg:grid"
          />

          <motion.ul
            className="grid grid-cols-1 gap-2.5 md:grid-cols-2 lg:hidden"
            initial="hidden"
            whileInView="show"
            viewport={{ once: true, margin: "-60px" }}
            variants={listVariants}
          >
            {points.map((point, index) => {
              const Icon = icons[index] ?? icons[0];
              return (
                <li key={point.title}>
                  <AppFeatureTile
                    icon={Icon}
                    title={point.title}
                    text={point.text}
                    tone={tone}
                  />
                </li>
              );
            })}
          </motion.ul>
        </div>

        <div className="mt-8 flex justify-center">
          <DownloadOpenButton dict={dict} className="btn-primary">
            {dict.nav.download}
          </DownloadOpenButton>
        </div>
      </div>
    </section>
  );
}

function FeatureColumn({
  points,
  icons,
  offset,
  tone,
  className,
}: {
  points: readonly Point[];
  icons: readonly IconType[];
  offset: number;
  tone: "customer" | "driver";
  className?: string;
}) {
  return (
    <motion.ul
      className={cn("grid gap-2.5", className)}
      initial="hidden"
      whileInView="show"
      viewport={{ once: true, margin: "-60px" }}
      variants={listVariants}
    >
      {points.map((point, index) => {
        const Icon = icons[offset + index] ?? icons[0];
        return (
          <li key={point.title}>
            <AppFeatureTile
              icon={Icon}
              title={point.title}
              text={point.text}
              tone={tone}
            />
          </li>
        );
      })}
    </motion.ul>
  );
}
