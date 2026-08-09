import { useCallback, useRef, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { authApi, buildSsoLoginUrl } from "@ecommerce/lib/api";
import { useAuthStore } from "@ecommerce/lib/store";
import { useRouter } from "@/i18n/navigation";

const SSO_NEXT_KEY = "sso_next";

/**
 * Starts the Keycloak SSO login. `next` is the in-app path to land on after
 * login completes; it's stashed in sessionStorage (the backend only allows a
 * fixed `/auth/callback` redirect, so the final destination rides client-side).
 */
export function useLogin() {
  const login = useCallback((next?: string) => {
    if (typeof window === "undefined") return;
    if (next) sessionStorage.setItem(SSO_NEXT_KEY, next);
    window.location.href = buildSsoLoginUrl();
  }, []);

  return { login, isPending: false };
}

/** Registration reuses the SSO flow — the Keycloak login page links to sign-up. */
export function useRegister() {
  const register = useCallback(() => {
    if (typeof window === "undefined") return;
    window.location.href = buildSsoLoginUrl();
  }, []);

  return { register };
}

/**
 * Runs on the `/auth/callback` page: swaps the single-use ticket for tokens,
 * pulls the profile, persists the session, then routes to `next`.
 */
export function useSsoCallback() {
  const { setAuth } = useAuthStore();
  const router = useRouter();
  const [status, setStatus] = useState<"loading" | "error">("loading");
  const ran = useRef(false);

  const run = useCallback(
    async (ticket: string) => {
      if (ran.current) return;
      ran.current = true;

      try {
        const res = await authApi.getSession(ticket);
        const tokens = res.data?.data;
        if (!tokens?.access_token) throw new Error("missing access token");

        // Set the token first so getProfile()'s interceptor can attach it.
        localStorage.setItem("access_token", tokens.access_token);

        let user = { id: 0, fullName: "", username: "", email: "", gender: "", roles: [] };
        try {
          const profileRes = await authApi.getProfile();
          if (profileRes.data?.data) user = profileRes.data.data;
        } catch {
          /* profile is best-effort; the token alone is enough to be logged in */
        }

        setAuth(user, tokens.access_token, tokens.refresh_token);

        const next = sessionStorage.getItem(SSO_NEXT_KEY) || "/";
        sessionStorage.removeItem(SSO_NEXT_KEY);
        router.replace(next);
        router.refresh();
      } catch {
        setStatus("error");
      }
    },
    [setAuth, router]
  );

  return { run, status };
}

export function useLogout() {
  const { logout } = useAuthStore();
  const router = useRouter();

  return useMutation({
    mutationFn: async () => {
      const refreshToken = localStorage.getItem("refresh_token");
      if (refreshToken) {
        await authApi.logout(refreshToken);
      }
    },
    onSuccess: () => {
      logout();
      router.push("/");
    },
    onError: () => {
      logout();
      router.push("/");
    },
  });
}
