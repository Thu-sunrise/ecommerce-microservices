"use client";

import { useTranslations } from "next-intl";
import { useProducts } from "@/hooks/useProducts";
import CategorySection from "./CategorySection";
import type { BrandChip } from "@/components/data/homeMock";

interface CategoryProductSectionProps {
  categoryId: number;
  categoryTitle: string;
  icon?: string;
  bannerTitle?: string;
  bannerSub?: string;
  bannerGradient?: string;
  brands?: BrandChip[];
}

export default function CategoryProductSection({
  categoryId,
  categoryTitle,
  icon = "🛍️",
  bannerTitle = "Sản phẩm nổi bật",
  bannerSub = "Khám phá ngay",
  bannerGradient = "from-primary-600 to-primary-700",
  brands = [],
}: CategoryProductSectionProps) {
  const t = useTranslations("Home");
  const { data: products = [] } = useProducts({ categoryId, page: 0, size: 5 });

  if (!products.length) return null;

  return (
    <CategorySection
      title={categoryTitle}
      icon={icon}
      href={`/products?categoryId=${categoryId}`}
      viewAllLabel={t("viewAll")}
      bannerTitle={bannerTitle}
      bannerSub={bannerSub}
      bannerCta={t("heroCta")}
      bannerGradient={bannerGradient}
      brands={brands}
      products={products}
    />
  );
}
