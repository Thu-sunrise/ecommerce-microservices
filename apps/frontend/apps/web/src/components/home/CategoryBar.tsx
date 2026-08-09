"use client";

import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { useCategories } from "@/hooks/useCategories";
import { homeStyles as s } from "./home.styles";
import { ListIcon } from "lucide-react"; // Fallback icon

export default function CategoryBar() {
  const t = useTranslations("Category");
  const { data: categoryData, isLoading } = useCategories(0, 10);
  const categories = categoryData?.data?.content || [];

  if (isLoading) {
    return (
      <div className={s.section}>
        <div className="flex justify-center p-4">Loading categories...</div>
      </div>
    );
  }

  return (
    <div className={s.section}>
      <div className={s.catGrid}>
        {categories.map((cat) => (
          <Link key={cat.categoryId} href={`/categories/${cat.categoryId}`} className={s.catItem}>
            <div className={s.catIcon}>
              {cat.imageUrl ? (
                <img src={cat.imageUrl} alt={cat.categoryTitle} className="w-8 h-8 rounded-full object-cover" />
              ) : (
                <ListIcon className="w-8 h-8 text-gray-500" />
              )}
            </div>
            <span className={s.catLabel}>{cat.categoryTitle}</span>
          </Link>
        ))}
      </div>
    </div>
  );
}
