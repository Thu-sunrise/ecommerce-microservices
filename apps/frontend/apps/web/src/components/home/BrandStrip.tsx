import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { homeStyles as s } from "./home.styles";

const brands = [
  { id: "b1", name: "Apple", href: "/brands/apple" },
  { id: "b2", name: "Samsung", href: "/brands/samsung" },
  { id: "b3", name: "Sony", href: "/brands/sony" },
  { id: "b4", name: "LG", href: "/brands/lg" },
  { id: "b5", name: "Asus", href: "/brands/asus" },
  { id: "b6", name: "Dell", href: "/brands/dell" },
];

export default async function BrandStrip() {
  const t = await getTranslations("Home");

  return (
    <section className={s.section}>
      <h2 className="text-lg md:text-xl font-bold text-gray-900 mb-4">{t("featuredBrands")}</h2>
      <div className={s.brandGrid}>
        {brands.map((brand) => (
          <Link key={brand.id} href={brand.href} className={s.brandCard}>
            {brand.name}
          </Link>
        ))}
      </div>
    </section>
  );
}
