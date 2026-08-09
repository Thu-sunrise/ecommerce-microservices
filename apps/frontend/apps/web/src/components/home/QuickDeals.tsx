import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { homeStyles as s } from "./home.styles";

const quickDeals = [
  { id: "qd1", key: "dealStudent", href: "/flash-sale", emoji: "🎓" },
  { id: "qd2", key: "dealB2B", href: "/products", emoji: "🏢" },
  { id: "qd3", key: "dealClearance", href: "/products", emoji: "🏷️" },
  { id: "qd4", key: "dealNews", href: "/products", emoji: "📰" },
];

export default async function QuickDeals() {
  const t = await getTranslations("Home");

  return (
    <div className={s.quickGrid}>
      {quickDeals.map((deal) => (
        <Link key={deal.id} href={deal.href} className={s.quickCard}>
          <span className={s.quickIcon}>{deal.emoji}</span>
          <span className={s.quickLabel}>{t(deal.key)}</span>
        </Link>
      ))}
    </div>
  );
}
