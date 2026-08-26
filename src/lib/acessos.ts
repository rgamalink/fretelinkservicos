import { supabase } from "@/integrations/supabase/client";

export type AcessoStatus = "pendente" | "aprovado" | "reprovado";
export type PerfilUsuario = "administrador" | "usuario";

export type UsuarioAcesso = {
  id: string;
  email: string | null;
  full_name: string | null;
  company: string | null;
  access_status: string;
  created_at: string;
  access_decided_at: string | null;
  role: PerfilUsuario;
};

/** Diz se o usuário logado tem a role 'approver' (independente do e-mail fixo). */
export async function souAdministrador(userId: string): Promise<boolean> {
  const { data, error } = await supabase
    .from("user_roles")
    .select("role")
    .eq("user_id", userId)
    .eq("role", "approver")
    .maybeSingle();
  if (error || !data) return false;
  return true;
}

/** Status de acesso do usuário logado. */
export async function meuAcesso(userId: string): Promise<AcessoStatus> {
  const { data, error } = await supabase
    .from("profiles")
    .select("access_status")
    .eq("id", userId)
    .maybeSingle();
  if (error || !data) return "pendente";
  return (data.access_status as AcessoStatus) ?? "pendente";
}

/** Lista todos os cadastros (apenas o aprovador tem permissão). */
export async function listarUsuarios(): Promise<UsuarioAcesso[]> {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, email, full_name, company, access_status, created_at, access_decided_at")
    .order("created_at", { ascending: false });
  if (error) throw error;

  const { data: rolesData, error: rolesError } = await supabase
    .from("user_roles")
    .select("user_id")
    .eq("role", "approver");
  if (rolesError) throw rolesError;
  const admins = new Set((rolesData ?? []).map((r) => r.user_id));

  return (data ?? []).map((p) => ({
    ...p,
    role: admins.has(p.id) ? "administrador" : "usuario",
  })) as UsuarioAcesso[];
}

/** Aprova ou reprova o acesso de um cadastro. */
export async function decidirAcesso(id: string, status: AcessoStatus) {
  const { data: userData } = await supabase.auth.getUser();
  const { error } = await supabase
    .from("profiles")
    .update({
      access_status: status,
      access_decided_at: new Date().toISOString(),
      access_decided_by: userData.user?.id ?? null,
    })
    .eq("id", id);
  if (error) throw error;
}

/** Altera o perfil (administrador/usuario) de um usuário — apenas administrador, via RPC. */
export async function definirPerfil(id: string, role: PerfilUsuario) {
  const { error } = await supabase.rpc("admin_set_user_role", {
    target_id: id,
    new_role: role,
  });
  if (error) throw error;
}

/** Exclui o cadastro (profiles + roles) de um usuário — apenas administrador, via RPC. */
export async function excluirUsuario(id: string) {
  const { error } = await supabase.rpc("admin_excluir_usuario", {
    target_id: id,
  });
  if (error) throw error;
}
