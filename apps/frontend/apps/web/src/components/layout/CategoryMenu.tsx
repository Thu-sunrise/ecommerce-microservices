"use client";

import { useState, useRef, useEffect } from "react";
import { useTranslations } from "next-intl";
import { Menu, ChevronRight } from "lucide-react";
import { Link } from "@/i18n/navigation";
import { useCategories } from "@/hooks/useCategories";
import { categoryMenuStyles as s } from "./categoryMenu.styles";

export default function CategoryMenu() {
  const t = useTranslations("Category");
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const { data } = useCategories(0, 20);
  const categories = data?.data?.content || [];

  // Random/fallback icon since DB does not store emojis
  const getIcon = (id: number) => {
    const icons = ["📱", "💻", "📲", "🎧", "⌚", "📷", "🏠", "🖥️", "🔌", "📺"];
    return icons[(id - 1) % icons.length] || "📦";
  };

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  return (
    <div className={s.root} ref={ref}>
      <button onClick={() => setOpen((o) => !o)} className={s.trigger}>
        <Menu className="h-4 w-4" /> {t("menuTitle")}
      </button>

      {open && (
        <div className={s.panel}>
          {categories.map((cat: any) => (
            <Link key={cat.categoryId} href={`/products?categoryId=${cat.categoryId}`} onClick={() => setOpen(false)} className={s.item}>
              <span className={s.itemEmoji}>{getIcon(cat.categoryId)}</span>
              <span className={s.itemLabel}>{cat.categoryTitle}</span>
              <ChevronRight className={s.itemCaret} />
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
