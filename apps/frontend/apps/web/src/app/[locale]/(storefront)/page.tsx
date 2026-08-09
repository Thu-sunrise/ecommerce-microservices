import { getTranslations } from "next-intl/server";
import { ShieldCheck, Truck, RefreshCw, Headphones } from "lucide-react";
import HeroSection from "@/components/home/HeroSection";
import QuickDeals from "@/components/home/QuickDeals";
import FlashSale from "@/components/home/FlashSale";
import HomeProductSections from "@/components/home/HomeProductSections";
import { homeStyles as s } from "@/components/home/home.styles";

export async function generateMetadata() {
  const t = await getTranslations("Home");
  return { title: t("metaTitle"), description: t("metaDesc") };
}

export default async function HomePage() {
  const t = await getTranslations("Home");

  const usp = [
    { icon: ShieldCheck, title: t("uspGenuine"), desc: t("uspGenuineDesc") },
    { icon: Truck, title: t("uspShipping"), desc: t("uspShippingDesc") },
    { icon: RefreshCw, title: t("uspReturn"), desc: t("uspReturnDesc") },
    { icon: Headphones, title: t("uspSupport"), desc: t("uspSupportDesc") },
  ];

  return (
    <div className="bg-[#f4f4f4]">
      <div className="max-w-7xl mx-auto px-3 md:px-4 py-4 space-y-4">
        <HeroSection />
        <QuickDeals />
        <FlashSale />

        <HomeProductSections />

        {/* USP strip */}
        <section className={s.section}>
          <div className={s.uspGrid}>
            {usp.map(({ icon: Icon, title, desc }) => (
              <div key={title} className={s.uspItem}>
                <div className={s.uspIcon}>
                  <Icon className="h-5 w-5 text-primary-600" />
                </div>
                <div>
                  <p className={s.uspTitle}>{title}</p>
                  <p className={s.uspDesc}>{desc}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
