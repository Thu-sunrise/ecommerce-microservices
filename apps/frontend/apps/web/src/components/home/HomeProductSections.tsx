"use client";

import { useTranslations } from "next-intl";
import { useProducts } from "@/hooks/useProducts";
import ProductRail from "./ProductRail";
import BrandStrip from "./BrandStrip";
import CategoryProductSection from "./CategoryProductSection";
import { useCategories } from "@/hooks/useCategories";

export default function HomeProductSections() {
  const t = useTranslations("Home");

  const { data: catData } = useCategories(0, 10);
  const categories = catData?.data?.content || [];

  const { data: hotProducts = [] } = useProducts({ page: 0, size: 5, sort: "productId,desc" });
  const { data: newArrivals = [] } = useProducts({ page: 1, size: 5, sort: "productId,desc" });

  const getIcon = (id: number) => {
    const icons = ["📱", "💻", "📲", "🎧", "⌚", "📷", "🏠", "🖥️", "🔌", "📺"];
    return icons[(id - 1) % icons.length] || "🛍️";
  };

  const getBannerGradient = (id: number) => {
    const gradients = [
      "from-primary-600 to-primary-700",
      "from-indigo-600 to-blue-700",
      "from-amber-500 to-orange-600",
      "from-emerald-600 to-teal-700",
      "from-purple-600 to-fuchsia-700"
    ];
    return gradients[(id - 1) % gradients.length] || gradients[0];
  };

  return (
    <>
      {hotProducts.length > 0 && (
        <ProductRail title={t("hotProducts")} icon="🔥" products={hotProducts} viewAllLabel={t("viewAll")} />
      )}

      {categories.map((cat: any) => (
        <CategoryProductSection
          key={cat.categoryId}
          categoryId={cat.categoryId}
          categoryTitle={cat.categoryTitle}
          icon={getIcon(cat.categoryId)}
          bannerTitle={cat.categoryTitle}
          bannerSub={t("phoneBannerSub")}
          bannerGradient={getBannerGradient(cat.categoryId)}
        />
      ))}

      {newArrivals.length > 0 && (
        <ProductRail title={t("newArrivals")} icon="🆕" products={newArrivals} viewAllLabel={t("viewAll")} />
      )}

      <BrandStrip />
    </>
  );
}
