import {
  BarChart,
  Button,
  Callout,
  Divider,
  H1,
  H2,
  PieChart,
  Pill,
  Row,
  Spacer,
  Stack,
  Text,
  TextInput,
  UsageBar,
  useCanvasState,
  useHostTheme,
  type CanvasHostTheme,
} from "cursor/canvas";

type Viewport = "mobile" | "tablet" | "wide";
type Screen =
  | "dashboard"
  | "transactions"
  | "accounts"
  | "budgets"
  | "goals"
  | "inbox"
  | "settings"
  | "addTx"
  | "family"
  | "auth";
type Locale = "it" | "en";

const VIEWPORT_SIZE: Record<Viewport, { width: number; height: number; label: string }> = {
  mobile: { width: 390, height: 780, label: "Mobile 390" },
  tablet: { width: 768, height: 900, label: "Tablet 768" },
  wide: { width: 1180, height: 780, label: "Wide 1180" },
};

const copy = {
  it: {
    brand: "Family Finance",
    family: "Famiglia Rossi",
    dashboard: "Panoramica",
    transactions: "Movimenti",
    accounts: "Conti",
    budgets: "Budget",
    goals: "Obiettivi",
    inbox: "Da confermare",
    settings: "Impostazioni",
    add: "Aggiungi",
    balance: "Saldo totale",
    spentMonth: "Speso questo mese",
    incomeMonth: "Entrate del mese",
    remaining: "Rimanente budget",
    recent: "Movimenti recenti",
    seeAll: "Vedi tutti",
    accountsTitle: "I tuoi conti",
    budgetsTitle: "Budget di settembre",
    goalsTitle: "Obiettivi di risparmio",
    inboxTitle: "Bozze da confermare",
    inboxHint:
      "Notifiche e scontrini diventano bozze Ingestion. Nessun movimento reale finché non confermi.",
    inboxFlowTitle: "Flusso ingest da notifica",
    inboxFlowSteps:
      "1. Arriva la notifica (es. Google Wallet) · 2. Parse → bozza · 3. Avviso “N bozze da confermare” · 4. Conferma / modifica / scarta",
    draftBadge: "Bozza",
    draftNotifyTitle: "2 bozze da confermare",
    draftNotifyBody: "Google Wallet · Coop, Shell — apri la coda per revisionare.",
    draftNotifyNote: "Anteprima notifica sistema (aggregata). Soppressa se l’app è già aperta su Da confermare.",
    noSilentCreate: "Creazione silenziosa disattivata: solo conferma esplicita.",
    edit: "Modifica",
    filters: "Filtri",
    search: "Cerca esercente o nota…",
    expense: "Uscita",
    income: "Entrata",
    transfer: "Trasferimento",
    refund: "Rimborso",
    newTx: "Nuovo movimento",
    save: "Salva",
    cancel: "Annulla",
    amount: "Importo",
    date: "Data contabile",
    category: "Categoria",
    account: "Conto",
    merchant: "Esercente",
    note: "Nota",
    language: "Lingua",
    members: "Membri",
    invite: "Invita",
    createFamily: "Crea famiglia",
    signIn: "Accedi",
    signUp: "Registrati",
    email: "Email",
    password: "Password",
    emptyTx: "Nessun movimento in questo periodo.",
    confirm: "Conferma",
    discard: "Scarta",
    possibleDup: "Possibile duplicato",
    needsReview: "Da rivedere",
    contribute: "Versa",
    of: "di",
    by: "da",
    navMore: "Altro",
    designNote: "Mock UI · Material 3 Expressive · nav bar / rail · shape + type emphasis",
  },
  en: {
    brand: "Family Finance",
    family: "Rossi Family",
    dashboard: "Overview",
    transactions: "Transactions",
    accounts: "Accounts",
    budgets: "Budgets",
    goals: "Goals",
    inbox: "To confirm",
    settings: "Settings",
    add: "Add",
    balance: "Total balance",
    spentMonth: "Spent this month",
    incomeMonth: "Income this month",
    remaining: "Budget remaining",
    recent: "Recent activity",
    seeAll: "See all",
    accountsTitle: "Your accounts",
    budgetsTitle: "September budgets",
    goalsTitle: "Savings goals",
    inboxTitle: "Drafts to confirm",
    inboxHint:
      "Notifications and receipts become Ingestion drafts. No real ledger entry until you confirm.",
    inboxFlowTitle: "Notification ingest flow",
    inboxFlowSteps:
      "1. Notification arrives (e.g. Google Wallet) · 2. Parse → draft · 3. “N drafts to confirm” alert · 4. Confirm / edit / discard",
    draftBadge: "Draft",
    draftNotifyTitle: "2 drafts to confirm",
    draftNotifyBody: "Google Wallet · Coop, Shell — open the queue to review.",
    draftNotifyNote: "System notification preview (aggregated). Suppressed if the app is already open on To confirm.",
    noSilentCreate: "Silent auto-create is off: explicit confirm only.",
    edit: "Edit",
    filters: "Filters",
    search: "Search merchant or note…",
    expense: "Expense",
    income: "Income",
    transfer: "Transfer",
    refund: "Refund",
    newTx: "New transaction",
    save: "Save",
    cancel: "Cancel",
    amount: "Amount",
    date: "Booking date",
    category: "Category",
    account: "Account",
    merchant: "Merchant",
    note: "Note",
    language: "Language",
    members: "Members",
    invite: "Invite",
    createFamily: "Create family",
    signIn: "Sign in",
    signUp: "Sign up",
    email: "Email",
    password: "Password",
    emptyTx: "No transactions in this period.",
    confirm: "Confirm",
    discard: "Discard",
    possibleDup: "Possible duplicate",
    needsReview: "Needs review",
    contribute: "Contribute",
    of: "of",
    by: "by",
    navMore: "More",
    designNote: "UI mock · Material 3 Expressive · nav bar / rail · shape + type emphasis",
  },
} as const;

/** M3 Expressive-ish shape tokens (mock): mix round + tighter for tension. */
const shape = {
  full: 999,
  xl: 28,
  lg: 20,
  md: 14,
  sm: 10,
  /** Asymmetric “expressive” card: large top-left / bottom-right */
  hero: "32px 16px 32px 16px",
  chip: 12,
} as const;

const NAV_GLYPH: Partial<Record<Screen, string>> = {
  dashboard: "H",
  transactions: "M",
  accounts: "C",
  budgets: "B",
  goals: "G",
  inbox: "I",
  settings: "S",
};

const TRANSACTIONS = [
  { id: "1", merchant: "Esselunga", cat: { it: "Spesa", en: "Groceries" }, amount: -87.42, date: "2026-09-25", who: "Giulia", type: "expense" as const },
  { id: "2", merchant: "Stipendio", cat: { it: "Stipendio", en: "Salary" }, amount: 2450, date: "2026-09-24", who: "Marco", type: "income" as const },
  { id: "3", merchant: "ENEL", cat: { it: "Utenze", en: "Utilities" }, amount: -112.3, date: "2026-09-22", who: "Marco", type: "expense" as const },
  { id: "4", merchant: "Carta → Contanti", cat: { it: "Trasferimento", en: "Transfer" }, amount: -100, date: "2026-09-21", who: "Giulia", type: "transfer" as const },
  { id: "5", merchant: "Amazon", cat: { it: "Shopping", en: "Shopping" }, amount: -34.99, date: "2026-09-20", who: "Giulia", type: "expense" as const },
  { id: "6", merchant: "Rimborso Trenitalia", cat: { it: "Trasporti", en: "Transport" }, amount: 28.5, date: "2026-09-18", who: "Marco", type: "refund" as const },
];

const ACCOUNTS = [
  { id: "a1", name: { it: "Conto corrente", en: "Checking" }, type: { it: "Banca", en: "Bank" }, balance: 4820.15 },
  { id: "a2", name: { it: "Carta di credito", en: "Credit card" }, type: { it: "Carta", en: "Card" }, balance: -312.4 },
  { id: "a3", name: { it: "Contanti", en: "Cash" }, type: { it: "Contanti", en: "Cash" }, balance: 180 },
  { id: "a4", name: { it: "PayPal", en: "PayPal" }, type: { it: "Wallet", en: "Wallet" }, balance: 95.2 },
];

const BUDGETS = [
  { id: "b1", name: { it: "Spesa", en: "Groceries" }, spent: 312, limit: 400, color: "green" as const },
  { id: "b2", name: { it: "Utenze", en: "Utilities" }, spent: 186, limit: 200, color: "orange" as const },
  { id: "b3", name: { it: "Trasporti", en: "Transport" }, spent: 95, limit: 150, color: "blue" as const },
  { id: "b4", name: { it: "Svago", en: "Leisure" }, spent: 210, limit: 180, color: "red" as const },
];

const GOALS = [
  { id: "g1", name: { it: "Vacanze estate", en: "Summer holiday" }, saved: 1850, target: 3000, due: "2027-06" },
  { id: "g2", name: { it: "Fondo emergenza", en: "Emergency fund" }, saved: 4200, target: 6000, due: "2027-12" },
];

const INBOX = [
  { id: "i1", merchant: "Coop", amount: 54.2, date: "2026-09-26", source: "OCR", status: "needsReview" as const },
  { id: "i2", merchant: "Esselunga", amount: 87.42, date: "2026-09-25", source: "Wallet", status: "possibleDuplicate" as const },
  { id: "i3", merchant: "Shell", amount: 62, date: "2026-09-25", source: "Wallet", status: "needsReview" as const },
];

function money(n: number, locale: Locale): string {
  return new Intl.NumberFormat(locale === "it" ? "it-IT" : "en-US", {
    style: "currency",
    currency: "EUR",
  }).format(n);
}

function formatDate(iso: string, locale: Locale): string {
  const [y, m, d] = iso.split("-").map(Number);
  return new Intl.DateTimeFormat(locale === "it" ? "it-IT" : "en-US", {
    day: "2-digit",
    month: "short",
  }).format(new Date(y, m - 1, d));
}

function DeviceChrome({
  viewport,
  children,
  theme,
}: {
  viewport: Viewport;
  children: ReturnType<typeof Stack>;
  theme: CanvasHostTheme;
}) {
  const size = VIEWPORT_SIZE[viewport];
  return (
    <div
      style={{
        width: size.width,
        maxWidth: "100%",
        height: size.height,
        border: `1px solid ${theme.stroke.secondary}`,
        borderRadius: viewport === "mobile" ? 36 : 20,
        background: theme.bg.editor,
        overflow: "hidden",
        display: "flex",
        flexDirection: "column",
        margin: "0 auto",
      }}
    >
      <div
        style={{
          height: 28,
          flexShrink: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: theme.fill.quaternary,
        }}
      >
        {viewport === "mobile" ? (
          <div
            style={{
              width: 108,
              height: 12,
              borderRadius: shape.full,
              background: theme.fill.secondary,
            }}
          />
        ) : (
          <Text size="small" tone="tertiary">
            {size.label} · M3 Expressive
          </Text>
        )}
      </div>
      <div style={{ flex: 1, minHeight: 0, display: "flex", overflow: "hidden" }}>{children}</div>
    </div>
  );
}

function NavItem({
  id,
  label,
  active,
  onClick,
  theme,
  layout,
}: {
  id: Screen;
  label: string;
  active: boolean;
  onClick: () => void;
  theme: CanvasHostTheme;
  /** vertical = rail; compact = phone nav bar; horizontal = tablet nav bar */
  layout: "vertical" | "compact" | "horizontal";
}) {
  const glyph = NAV_GLYPH[id] ?? label.slice(0, 1);
  const indicator = (
    <div
      style={{
        width: layout === "vertical" ? 48 : layout === "horizontal" ? "auto" : 56,
        minWidth: layout === "horizontal" ? 72 : undefined,
        height: layout === "horizontal" ? 36 : 28,
        borderRadius: shape.full,
        background: active ? theme.accent.primary : "transparent",
        color: active ? theme.text.onAccent : theme.text.tertiary,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        padding: layout === "horizontal" ? "0 14px" : 0,
        fontSize: 12,
        fontWeight: 700,
        letterSpacing: 0.2,
      }}
    >
      {layout === "horizontal" ? (
        <>
          <span>{glyph}</span>
          <span style={{ fontWeight: active ? 700 : 500, fontSize: 12 }}>{label}</span>
        </>
      ) : (
        glyph
      )}
    </div>
  );

  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        all: "unset",
        cursor: "pointer",
        display: "flex",
        flexDirection: layout === "horizontal" ? "row" : "column",
        alignItems: layout === "vertical" ? "stretch" : "center",
        justifyContent: "center",
        gap: layout === "compact" ? 4 : 6,
        padding: layout === "vertical" ? "6px 10px" : "6px 4px",
        flex: layout === "vertical" ? undefined : 1,
        minWidth: 0,
        borderRadius: shape.md,
        background: layout === "vertical" && active ? theme.fill.secondary : "transparent",
      }}
    >
      {layout === "vertical" ? (
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          {indicator}
          <span
            style={{
              color: active ? theme.text.primary : theme.text.tertiary,
              fontSize: 13,
              fontWeight: active ? 700 : 500,
            }}
          >
            {label}
          </span>
        </div>
      ) : layout === "horizontal" ? (
        indicator
      ) : (
        <>
          {indicator}
          <span
            style={{
              color: active ? theme.text.primary : theme.text.tertiary,
              fontSize: 11,
              fontWeight: active ? 700 : 500,
              textAlign: "center",
              lineHeight: 1.2,
            }}
          >
            {label}
          </span>
        </>
      )}
    </button>
  );
}

function TxRow({
  merchant,
  category,
  amount,
  date,
  who,
  locale,
  theme,
}: {
  merchant: string;
  category: string;
  amount: number;
  date: string;
  who: string;
  locale: Locale;
  theme: CanvasHostTheme;
}) {
  const positive = amount > 0;
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 14,
        padding: "12px 14px",
        borderRadius: shape.lg,
        background: theme.fill.quaternary,
      }}
    >
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: "40% 60% 55% 45%",
          background: theme.fill.secondary,
          flexShrink: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 15,
          fontWeight: 700,
          color: theme.accent.primary,
        }}
      >
        {merchant.slice(0, 1)}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <Text weight="bold" truncate style={{ margin: 0, fontSize: 14 }}>
          {merchant}
        </Text>
        <Text size="small" tone="tertiary" truncate style={{ margin: 0 }}>
          {category} · {formatDate(date, locale)} · {copy[locale].by} {who}
        </Text>
      </div>
      <Text
        weight="bold"
        style={{
          margin: 0,
          fontSize: 15,
          color: positive ? theme.chart.palette.green : theme.text.primary,
          whiteSpace: "nowrap",
        }}
      >
        {positive ? "+" : ""}
        {money(amount, locale)}
      </Text>
    </div>
  );
}

function ProgressBar({
  value,
  max,
  over,
  theme,
}: {
  value: number;
  max: number;
  over?: boolean;
  theme: CanvasHostTheme;
}) {
  const pct = Math.min(100, Math.round((value / max) * 100));
  return (
    <div
      style={{
        height: 12,
        borderRadius: shape.full,
        background: theme.fill.tertiary,
        overflow: "hidden",
      }}
    >
      <div
        style={{
          width: `${pct}%`,
          height: "100%",
          background: over ? theme.chart.palette.darkAmber : theme.accent.primary,
          borderRadius: shape.full,
        }}
      />
    </div>
  );
}

function Fab({ label, onClick, theme }: { label: string; onClick: () => void; theme: CanvasHostTheme }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        all: "unset",
        cursor: "pointer",
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        padding: "14px 22px",
        borderRadius: shape.lg,
        background: theme.accent.primary,
        color: theme.text.onAccent,
        fontWeight: 700,
        fontSize: 14,
      }}
    >
      <span style={{ fontSize: 18, lineHeight: 1 }}>+</span>
      {label}
    </button>
  );
}

function AppShell({
  viewport,
  screen,
  setScreen,
  locale,
  theme,
  children,
}: {
  viewport: Viewport;
  screen: Screen;
  setScreen: (s: Screen) => void;
  locale: Locale;
  theme: CanvasHostTheme;
  children: ReturnType<typeof Stack>;
}) {
  const t = copy[locale];
  const primaryNav: { id: Screen; label: string }[] =
    viewport === "mobile"
      ? [
          { id: "dashboard", label: t.dashboard },
          { id: "transactions", label: t.transactions },
          { id: "budgets", label: t.budgets },
          { id: "inbox", label: t.inbox },
          { id: "settings", label: t.navMore },
        ]
      : [
          { id: "dashboard", label: t.dashboard },
          { id: "transactions", label: t.transactions },
          { id: "accounts", label: t.accounts },
          { id: "budgets", label: t.budgets },
          { id: "goals", label: t.goals },
          { id: "inbox", label: t.inbox },
          { id: "settings", label: t.settings },
        ];

  const showRail = viewport === "wide";
  const showBottom = viewport === "mobile" || viewport === "tablet";
  const overlay = screen === "addTx" || screen === "auth" || screen === "family";
  const navLayout = viewport === "tablet" ? "horizontal" : "compact";

  const content = (
    <div
      style={{
        flex: 1,
        minWidth: 0,
        display: "flex",
        flexDirection: "column",
        background: theme.bg.editor,
        position: "relative",
      }}
    >
      {!overlay && (
        <div
          style={{
            padding: viewport === "mobile" ? "14px 18px 8px" : "18px 28px 10px",
            display: "flex",
            alignItems: "flex-end",
            gap: 12,
          }}
        >
          <div style={{ flex: 1, minWidth: 0 }}>
            <Text size="small" tone="tertiary" style={{ margin: 0, fontWeight: 600, letterSpacing: 0.4 }}>
              {t.brand.toUpperCase()}
            </Text>
            <Text weight="bold" style={{ margin: 0, fontSize: viewport === "mobile" ? 22 : 26, lineHeight: 1.15 }}>
              {t.family}
            </Text>
          </div>
          {viewport !== "mobile" && <Fab label={t.add} onClick={() => setScreen("addTx")} theme={theme} />}
        </div>
      )}
      <div
        style={{
          flex: 1,
          overflow: "auto",
          padding: viewport === "mobile" ? "8px 16px 72px" : "8px 28px 24px",
        }}
      >
        {children}
      </div>
      {viewport === "mobile" && !overlay && (
        <div style={{ position: "absolute", right: 18, bottom: 78, zIndex: 2 }}>
          <Fab label={t.add} onClick={() => setScreen("addTx")} theme={theme} />
        </div>
      )}
      {showBottom && !overlay && (
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: viewport === "tablet" ? 8 : 0,
            justifyContent: viewport === "tablet" ? "center" : "stretch",
            borderTop: `1px solid ${theme.stroke.tertiary}`,
            background: theme.bg.chrome,
            padding: viewport === "tablet" ? "10px 16px 14px" : "8px 6px 12px",
          }}
        >
          {primaryNav.map((item) => (
            <NavItem
              key={item.id}
              id={item.id}
              label={item.label}
              active={
                screen === item.id ||
                (item.id === "settings" && ["accounts", "goals", "settings"].includes(screen))
              }
              onClick={() => setScreen(item.id)}
              theme={theme}
              layout={navLayout}
            />
          ))}
        </div>
      )}
    </div>
  );

  if (!showRail) return content;

  return (
    <>
      <div
        style={{
          width: 236,
          flexShrink: 0,
          borderRight: `1px solid ${theme.stroke.tertiary}`,
          background: theme.fill.quaternary,
          padding: "20px 12px",
          display: "flex",
          flexDirection: "column",
          gap: 6,
        }}
      >
        <div style={{ padding: "4px 12px 18px" }}>
          <Text weight="bold" style={{ margin: 0, fontSize: 18 }}>
            {t.brand}
          </Text>
          <Text size="small" tone="tertiary" style={{ margin: 0 }}>
            {t.family}
          </Text>
        </div>
        <div style={{ padding: "0 8px 16px" }}>
          <Fab label={t.add} onClick={() => setScreen("addTx")} theme={theme} />
        </div>
        {primaryNav.map((item) => (
          <NavItem
            key={item.id}
            id={item.id}
            label={item.label}
            active={screen === item.id}
            onClick={() => setScreen(item.id)}
            theme={theme}
            layout="vertical"
          />
        ))}
      </div>
      {content}
    </>
  );
}

function DashboardScreen({
  locale,
  viewport,
  setScreen,
  theme,
}: {
  locale: Locale;
  viewport: Viewport;
  setScreen: (s: Screen) => void;
  theme: CanvasHostTheme;
}) {
  const t = copy[locale];
  return (
    <Stack gap={18}>
      <div
        style={{
          padding: viewport === "mobile" ? "22px 20px" : "28px 28px",
          borderRadius: shape.hero,
          background: theme.fill.secondary,
        }}
      >
        <Text size="small" tone="secondary" weight="semibold" style={{ margin: 0, letterSpacing: 0.3 }}>
          {t.balance}
        </Text>
        <Text
          weight="bold"
          style={{
            margin: "6px 0 16px",
            fontSize: viewport === "mobile" ? 36 : 44,
            lineHeight: 1.05,
            letterSpacing: -0.8,
          }}
        >
          {money(4783.0, locale)}
        </Text>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: viewport === "mobile" ? "1fr 1fr" : "repeat(3, minmax(0, 1fr))",
            gap: 10,
          }}
        >
          {[
            { label: t.spentMonth, value: money(1842.5, locale) },
            { label: t.incomeMonth, value: money(2450, locale) },
            { label: t.remaining, value: money(327.5, locale) },
          ]
            .slice(0, viewport === "mobile" ? 2 : 3)
            .map((s) => (
              <div
                key={s.label}
                style={{
                  padding: "12px 14px",
                  borderRadius: shape.md,
                  background: theme.bg.editor,
                }}
              >
                <Text size="small" tone="tertiary" style={{ margin: 0 }}>
                  {s.label}
                </Text>
                <Text weight="bold" style={{ margin: "4px 0 0", fontSize: 16 }}>
                  {s.value}
                </Text>
              </div>
            ))}
        </div>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: viewport === "mobile" ? "1fr" : "1.2fr 1fr",
          gap: 16,
        }}
      >
        <div
          style={{
            padding: 18,
            borderRadius: shape.xl,
            background: theme.fill.quaternary,
          }}
        >
          <Text weight="bold" style={{ margin: "0 0 12px", fontSize: 16 }}>
            {locale === "it" ? "Andamento mensile" : "Monthly trend"}
          </Text>
          <BarChart
            categories={["Mag", "Giu", "Lug", "Ago", "Set"]}
            series={[
              { name: locale === "it" ? "Uscite" : "Expenses", data: [1600, 1750, 2100, 1900, 1842], tone: "danger" },
              { name: locale === "it" ? "Entrate" : "Income", data: [2400, 2400, 2450, 2450, 2450], tone: "success" },
            ]}
            height={180}
          />
          <Text size="small" tone="tertiary" style={{ margin: "8px 0 0" }}>
            Source: stats rollup · Sep 2026
          </Text>
        </div>
        <div
          style={{
            padding: 18,
            borderRadius: shape.xl,
            background: theme.fill.quaternary,
          }}
        >
          <Text weight="bold" style={{ margin: "0 0 12px", fontSize: 16 }}>
            {locale === "it" ? "Spese per categoria" : "Spend by category"}
          </Text>
          <PieChart
            data={[
              { label: locale === "it" ? "Spesa" : "Groceries", value: 312 },
              { label: locale === "it" ? "Utenze" : "Utilities", value: 186 },
              { label: locale === "it" ? "Trasporti" : "Transport", value: 95 },
              { label: locale === "it" ? "Svago" : "Leisure", value: 210 },
              { label: locale === "it" ? "Altro" : "Other", value: 140 },
            ]}
            size={160}
          />
        </div>
      </div>

      <Stack gap={10}>
        <Row align="center" justify="space-between">
          <Text weight="bold" style={{ margin: 0, fontSize: 16 }}>
            {t.recent}
          </Text>
          <Button variant="ghost" onClick={() => setScreen("transactions")}>
            {t.seeAll}
          </Button>
        </Row>
        {TRANSACTIONS.slice(0, viewport === "mobile" ? 4 : 5).map((tx) => (
          <TxRow
            key={tx.id}
            merchant={tx.merchant}
            category={tx.cat[locale]}
            amount={tx.amount}
            date={tx.date}
            who={tx.who}
            locale={locale}
            theme={theme}
          />
        ))}
      </Stack>

      {viewport !== "mobile" && (
        <div
          style={{
            padding: 18,
            borderRadius: shape.xl,
            background: theme.fill.quaternary,
          }}
        >
          <Text weight="bold" style={{ margin: "0 0 14px", fontSize: 16 }}>
            {t.budgetsTitle}
          </Text>
          <Stack gap={12}>
            {BUDGETS.slice(0, 3).map((b) => (
              <UsageBar
                key={b.id}
                total={b.limit}
                segments={[{ id: b.id, value: Math.min(b.spent, b.limit), color: b.color }]}
                topLeftLabel={b.name[locale]}
                topRightLabel={`${money(b.spent, locale)} / ${money(b.limit, locale)}`}
              />
            ))}
          </Stack>
        </div>
      )}
    </Stack>
  );
}

function TransactionsScreen({ locale, theme }: { locale: Locale; theme: CanvasHostTheme }) {
  const t = copy[locale];
  const [q, setQ] = useCanvasState("txSearch", "");
  const filtered = TRANSACTIONS.filter(
    (tx) =>
      !q ||
      tx.merchant.toLowerCase().includes(q.toLowerCase()) ||
      tx.cat[locale].toLowerCase().includes(q.toLowerCase()),
  );
  return (
    <Stack gap={12}>
      <Row gap={8} wrap>
        <TextInput value={q} onChange={setQ} placeholder={t.search} style={{ flex: 1, minWidth: 160 }} />
        <Pill>{t.filters}</Pill>
        <Pill active>{locale === "it" ? "Settembre" : "September"}</Pill>
      </Row>
      <Row gap={6} wrap>
        <Pill size="sm">{t.expense}</Pill>
        <Pill size="sm">{t.income}</Pill>
        <Pill size="sm">{t.transfer}</Pill>
        <Pill size="sm">{t.refund}</Pill>
      </Row>
      {filtered.length === 0 ? (
        <Callout tone="neutral" title={t.emptyTx} />
      ) : (
        filtered.map((tx) => (
          <TxRow
            key={tx.id}
            merchant={tx.merchant}
            category={tx.cat[locale]}
            amount={tx.amount}
            date={tx.date}
            who={tx.who}
            locale={locale}
            theme={theme}
          />
        ))
      )}
    </Stack>
  );
}

function AccountsScreen({ locale, theme }: { locale: Locale; theme: CanvasHostTheme }) {
  const t = copy[locale];
  return (
    <Stack gap={12}>
      <Text weight="bold" style={{ margin: 0, fontSize: 18 }}>
        {t.accountsTitle}
      </Text>
      {ACCOUNTS.map((a, i) => (
        <div
          key={a.id}
          style={{
            padding: "18px 18px",
            borderRadius: i % 2 === 0 ? shape.hero : shape.xl,
            background: theme.fill.quaternary,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            gap: 12,
          }}
        >
          <div>
            <Text weight="bold" style={{ margin: 0, fontSize: 15 }}>
              {a.name[locale]}
            </Text>
            <Text size="small" tone="tertiary" style={{ margin: 0 }}>
              {a.type[locale]}
            </Text>
          </div>
          <Text
            weight="bold"
            style={{
              margin: 0,
              fontSize: 18,
              color: a.balance < 0 ? theme.chart.palette.darkAmber : theme.text.primary,
            }}
          >
            {money(a.balance, locale)}
          </Text>
        </div>
      ))}
      <Callout tone="info" title={locale === "it" ? "Archiviazione, non delete" : "Archive, never delete"}>
        {locale === "it"
          ? "I conti archiviati restano nello storico. Il saldo deriva da opening + movimenti."
          : "Archived accounts stay in history. Balance = opening + ledger movements."}
      </Callout>
    </Stack>
  );
}

function BudgetsScreen({ locale, theme }: { locale: Locale; theme: CanvasHostTheme }) {
  const t = copy[locale];
  return (
    <Stack gap={14}>
      <Text weight="bold" style={{ margin: 0, fontSize: 18 }}>
        {t.budgetsTitle}
      </Text>
      {BUDGETS.map((b) => {
        const over = b.spent > b.limit;
        const pct = Math.round((b.spent / b.limit) * 100);
        return (
          <div
            key={b.id}
            style={{
              padding: 18,
              borderRadius: shape.xl,
              background: theme.fill.quaternary,
            }}
          >
            <Row align="center" justify="space-between" style={{ marginBottom: 12 }}>
              <Text weight="bold" style={{ margin: 0, fontSize: 15 }}>
                {b.name[locale]}
              </Text>
              <div
                style={{
                  padding: "6px 12px",
                  borderRadius: shape.full,
                  background: over || pct >= 80 ? theme.accent.primary : theme.fill.secondary,
                  color: over || pct >= 80 ? theme.text.onAccent : theme.text.secondary,
                  fontSize: 12,
                  fontWeight: 700,
                }}
              >
                {pct}%
              </div>
            </Row>
            <ProgressBar value={b.spent} max={b.limit} over={over} theme={theme} />
            <Row justify="space-between" style={{ marginTop: 10 }}>
              <Text size="small" tone="secondary" style={{ margin: 0 }}>
                {money(b.spent, locale)} {t.of} {money(b.limit, locale)}
              </Text>
              {over && (
                <Text size="small" weight="semibold" style={{ margin: 0, color: theme.chart.palette.darkAmber }}>
                  {locale === "it" ? "Limite superato" : "Over limit"}
                </Text>
              )}
            </Row>
          </div>
        );
      })}
    </Stack>
  );
}

function GoalsScreen({ locale, theme }: { locale: Locale; theme: CanvasHostTheme }) {
  const t = copy[locale];
  return (
    <Stack gap={14}>
      <Text weight="bold" style={{ margin: 0, fontSize: 18 }}>
        {t.goalsTitle}
      </Text>
      <Callout tone="neutral" title={locale === "it" ? "Obiettivo virtuale" : "Virtual goal"}>
        {locale === "it"
          ? "I versamenti non muovono il saldo del conto: i soldi restano lì."
          : "Contributions do not move account balances — the money stays where it is."}
      </Callout>
      {GOALS.map((g) => (
        <div
          key={g.id}
          style={{
            padding: 18,
            borderRadius: shape.hero,
            background: theme.fill.secondary,
          }}
        >
          <Row align="center" justify="space-between" style={{ marginBottom: 12 }}>
            <div>
              <Text weight="bold" style={{ margin: 0, fontSize: 16 }}>
                {g.name[locale]}
              </Text>
              <Text size="small" tone="tertiary" style={{ margin: 0 }}>
                {locale === "it" ? "Scadenza" : "Due"} {g.due}
              </Text>
            </div>
            <Button variant="secondary">{t.contribute}</Button>
          </Row>
          <ProgressBar value={g.saved} max={g.target} theme={theme} />
          <Text size="small" tone="secondary" weight="semibold" style={{ margin: "10px 0 0" }}>
            {money(g.saved, locale)} {t.of} {money(g.target, locale)}
          </Text>
        </div>
      ))}
    </Stack>
  );
}

function InboxScreen({ locale, theme }: { locale: Locale; theme: CanvasHostTheme }) {
  const t = copy[locale];
  return (
    <Stack gap={14}>
      <div>
        <Text weight="bold" style={{ margin: 0, fontSize: 18 }}>
          {t.inboxTitle}
        </Text>
        <Text size="small" tone="secondary" style={{ margin: "4px 0 0" }}>
          {t.inboxHint}
        </Text>
      </div>

      <Callout tone="info" title={t.inboxFlowTitle}>
        {t.inboxFlowSteps}
      </Callout>

      <div
        style={{
          padding: 14,
          borderRadius: shape.lg,
          background: theme.fill.secondary,
          border: `1px solid ${theme.stroke.tertiary}`,
        }}
      >
        <Row align="center" gap={10}>
          <div
            style={{
              width: 40,
              height: 40,
              borderRadius: shape.md,
              background: theme.accent.primary,
              color: theme.text.onAccent,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 13,
              fontWeight: 700,
              flexShrink: 0,
            }}
          >
            FF
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <Text weight="bold" style={{ margin: 0, fontSize: 14 }}>
              {t.draftNotifyTitle}
            </Text>
            <Text size="small" tone="secondary" style={{ margin: "2px 0 0" }}>
              {t.draftNotifyBody}
            </Text>
          </div>
        </Row>
        <Text size="small" tone="tertiary" style={{ margin: "10px 0 0" }}>
          {t.draftNotifyNote}
        </Text>
      </div>

      <Text size="small" weight="semibold" tone="secondary" style={{ margin: 0 }}>
        {t.noSilentCreate}
      </Text>

      {INBOX.map((item) => (
        <div
          key={item.id}
          style={{
            padding: 18,
            borderRadius: shape.xl,
            background: theme.fill.quaternary,
          }}
        >
          <Row align="center" gap={8} style={{ marginBottom: 10 }} wrap>
            <div
              style={{
                padding: "5px 12px",
                borderRadius: shape.full,
                background: theme.fill.secondary,
                color: theme.text.secondary,
                fontSize: 11,
                fontWeight: 700,
              }}
            >
              {t.draftBadge}
            </div>
            <div
              style={{
                padding: "5px 12px",
                borderRadius: shape.full,
                background:
                  item.status === "possibleDuplicate" ? theme.chart.palette.darkAmber : theme.accent.primary,
                color: theme.text.onAccent,
                fontSize: 11,
                fontWeight: 700,
              }}
            >
              {item.status === "possibleDuplicate" ? t.possibleDup : t.needsReview}
            </div>
            <Text size="small" tone="tertiary" style={{ margin: 0 }}>
              {item.source}
            </Text>
            <Spacer />
            <Text weight="bold" style={{ margin: 0, fontSize: 16 }}>
              {money(item.amount, locale)}
            </Text>
          </Row>
          <Text weight="bold" style={{ margin: 0, fontSize: 15 }}>
            {item.merchant}
          </Text>
          <Text size="small" tone="tertiary" style={{ margin: "2px 0 14px" }}>
            {formatDate(item.date, locale)}
            {item.source === "Wallet"
              ? locale === "it"
                ? " · da notifica (non salvata grezza)"
                : " · from notification (raw text not stored)"
              : ""}
          </Text>
          <Row gap={8} wrap>
            <Button variant="primary">{t.confirm}</Button>
            <Button variant="secondary">{t.edit}</Button>
            <Button variant="ghost">{t.discard}</Button>
          </Row>
        </div>
      ))}
    </Stack>
  );
}

function SettingsScreen({
  locale,
  setLocale,
  setScreen,
  theme,
}: {
  locale: Locale;
  setLocale: (l: Locale) => void;
  setScreen: (s: Screen) => void;
  theme: CanvasHostTheme;
}) {
  const t = copy[locale];
  return (
    <Stack gap={20}>
      <Stack gap={8}>
        <Text weight="semibold" style={{ margin: 0 }}>
          {t.language}
        </Text>
        <Row gap={8}>
          <Button variant={locale === "it" ? "primary" : "secondary"} onClick={() => setLocale("it")}>
            Italiano
          </Button>
          <Button variant={locale === "en" ? "primary" : "secondary"} onClick={() => setLocale("en")}>
            English
          </Button>
        </Row>
      </Stack>
      <Divider />
      <Stack gap={8}>
        <Text weight="semibold" style={{ margin: 0 }}>
          {t.members}
        </Text>
        {[
          { name: "Marco", role: "Admin" },
          { name: "Giulia", role: "Member" },
        ].map((m) => (
          <Row key={m.name} align="center" justify="space-between">
            <Text style={{ margin: 0 }}>{m.name}</Text>
            <Pill size="sm">{m.role}</Pill>
          </Row>
        ))}
        <Button variant="secondary" onClick={() => setScreen("family")}>
          {t.invite}
        </Button>
      </Stack>
      <Divider />
      <Stack gap={8}>
        <Button variant="ghost" onClick={() => setScreen("accounts")}>
          {t.accounts}
        </Button>
        <Button variant="ghost" onClick={() => setScreen("goals")}>
          {t.goals}
        </Button>
        <Button variant="ghost" onClick={() => setScreen("auth")}>
          {locale === "it" ? "Schermata accesso (preview)" : "Auth screen (preview)"}
        </Button>
      </Stack>
      <Text size="small" tone="quaternary">
        EUR · Europe/Rome · shared ledger
      </Text>
    </Stack>
  );
}

function AddTxScreen({
  locale,
  setScreen,
  theme,
}: {
  locale: Locale;
  setScreen: (s: Screen) => void;
  theme: CanvasHostTheme;
}) {
  const t = copy[locale];
  const [type, setType] = useCanvasState<"expense" | "income" | "transfer" | "refund">("addTxType", "expense");
  const [amount, setAmount] = useCanvasState("addTxAmount", locale === "it" ? "54,20" : "54.20");
  return (
    <Stack gap={18}>
      <Row align="center">
        <Button variant="ghost" onClick={() => setScreen("dashboard")}>
          ←
        </Button>
        <Text weight="bold" style={{ margin: 0, fontSize: 20 }}>
          {t.newTx}
        </Text>
      </Row>
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          gap: 4,
          padding: 4,
          borderRadius: shape.full,
          background: theme.fill.tertiary,
        }}
      >
        {(
          [
            ["expense", t.expense],
            ["income", t.income],
            ["transfer", t.transfer],
            ["refund", t.refund],
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            onClick={() => setType(id)}
            style={{
              all: "unset",
              cursor: "pointer",
              flex: "1 1 auto",
              textAlign: "center",
              padding: "10px 14px",
              borderRadius: shape.full,
              background: type === id ? theme.accent.primary : "transparent",
              color: type === id ? theme.text.onAccent : theme.text.secondary,
              fontWeight: type === id ? 700 : 500,
              fontSize: 13,
            }}
          >
            {label}
          </button>
        ))}
      </div>
      <Stack gap={6}>
        <Text size="small" tone="secondary" weight="semibold" style={{ margin: 0 }}>
          {t.amount}
        </Text>
        <TextInput
          value={amount}
          onChange={setAmount}
          style={{ fontSize: 28, fontWeight: 700, height: 48, borderRadius: shape.md }}
        />
      </Stack>
      <Stack gap={6}>
        <Text size="small" tone="secondary" style={{ margin: 0 }}>
          {t.date}
        </Text>
        <TextInput value="2026-09-26" onChange={() => {}} />
      </Stack>
      {type !== "transfer" && (
        <Stack gap={6}>
          <Text size="small" tone="secondary" style={{ margin: 0 }}>
            {t.category}
          </Text>
          <Row gap={6} wrap>
            <Pill active>{locale === "it" ? "Spesa" : "Groceries"}</Pill>
            <Pill>{locale === "it" ? "Utenze" : "Utilities"}</Pill>
            <Pill>{locale === "it" ? "Trasporti" : "Transport"}</Pill>
          </Row>
        </Stack>
      )}
      <Stack gap={6}>
        <Text size="small" tone="secondary" style={{ margin: 0 }}>
          {t.account}
        </Text>
        <Row gap={6} wrap>
          <Pill active>{locale === "it" ? "Conto corrente" : "Checking"}</Pill>
          <Pill>{locale === "it" ? "Contanti" : "Cash"}</Pill>
        </Row>
      </Stack>
      {type === "transfer" && (
        <Callout tone="info" title={locale === "it" ? "Due gambe atomiche" : "Atomic two-leg transfer"}>
          {locale === "it"
            ? "Source e destination con lo stesso transferId, creati via callable."
            : "Source and destination share one transferId, created via callable."}
        </Callout>
      )}
      <Stack gap={6}>
        <Text size="small" tone="secondary" style={{ margin: 0 }}>
          {t.merchant}
        </Text>
        <TextInput value="Coop" onChange={() => {}} />
      </Stack>
      <Stack gap={6}>
        <Text size="small" tone="secondary" style={{ margin: 0 }}>
          {t.note}
        </Text>
        <TextInput value="" onChange={() => {}} placeholder="…" />
      </Stack>
      <Row gap={8}>
        <Button variant="primary" onClick={() => setScreen("transactions")}>
          {t.save}
        </Button>
        <Button variant="ghost" onClick={() => setScreen("dashboard")}>
          {t.cancel}
        </Button>
      </Row>
    </Stack>
  );
}

function AuthScreen({ locale, setScreen, theme }: { locale: Locale; setScreen: (s: Screen) => void; theme: CanvasHostTheme }) {
  const t = copy[locale];
  return (
    <Stack gap={20} style={{ maxWidth: 380, margin: "28px auto" }}>
      <div
        style={{
          padding: "24px 20px",
          borderRadius: shape.hero,
          background: theme.fill.secondary,
        }}
      >
        <Text weight="bold" style={{ margin: 0, fontSize: 32, letterSpacing: -0.6, lineHeight: 1.1 }}>
          {t.brand}
        </Text>
        <Text tone="secondary" style={{ margin: "10px 0 0" }}>
          {locale === "it"
            ? "Libro mastro familiare condiviso."
            : "Your shared family ledger."}
        </Text>
      </div>
      <Stack gap={6}>
        <Text size="small" tone="secondary" weight="semibold" style={{ margin: 0 }}>
          {t.email}
        </Text>
        <TextInput value="marco@rossi.family" onChange={() => {}} />
      </Stack>
      <Stack gap={6}>
        <Text size="small" tone="secondary" weight="semibold" style={{ margin: 0 }}>
          {t.password}
        </Text>
        <TextInput type="password" value="••••••••" onChange={() => {}} />
      </Stack>
      <Fab label={t.signIn} onClick={() => setScreen("dashboard")} theme={theme} />
      <Button variant="secondary">{t.signUp}</Button>
      <Button variant="ghost" onClick={() => setScreen("family")}>
        {locale === "it" ? "Continua con Google" : "Continue with Google"}
      </Button>
    </Stack>
  );
}

function FamilyScreen({ locale, setScreen }: { locale: Locale; setScreen: (s: Screen) => void }) {
  const t = copy[locale];
  return (
    <Stack gap={20} style={{ maxWidth: 420, margin: "12px auto" }}>
      <Row align="center">
        <Button variant="ghost" onClick={() => setScreen("settings")}>
          ←
        </Button>
        <Text weight="semibold" style={{ margin: 0, fontSize: 16 }}>
          {t.createFamily}
        </Text>
      </Row>
      <Stack gap={6}>
        <Text size="small" tone="secondary" style={{ margin: 0 }}>
          {locale === "it" ? "Nome famiglia" : "Family name"}
        </Text>
        <TextInput value={t.family} onChange={() => {}} />
      </Stack>
      <Stack gap={6}>
        <Text size="small" tone="secondary" style={{ margin: 0 }}>
          {locale === "it" ? "Valuta (immutabile)" : "Currency (immutable)"}
        </Text>
        <Pill active>EUR</Pill>
      </Stack>
      <Divider />
      <Stack gap={8}>
        <Text weight="semibold" style={{ margin: 0 }}>
          {t.invite}
        </Text>
        <TextInput value="giulia@rossi.family" onChange={() => {}} />
        <Callout tone="info" title={locale === "it" ? "Emulator" : "Emulator"}>
          {locale === "it"
            ? "In locale l’admin copia il link invito. Trigger Email solo su progetto reale."
            : "Locally the admin copies the invite link. Trigger Email only on a real project."}
        </Callout>
        <Button variant="primary" onClick={() => setScreen("dashboard")}>
          {locale === "it" ? "Copia link invito" : "Copy invite link"}
        </Button>
      </Stack>
    </Stack>
  );
}

function ScreenBody({
  screen,
  setScreen,
  locale,
  setLocale,
  viewport,
  theme,
}: {
  screen: Screen;
  setScreen: (s: Screen) => void;
  locale: Locale;
  setLocale: (l: Locale) => void;
  viewport: Viewport;
  theme: CanvasHostTheme;
}) {
  switch (screen) {
    case "dashboard":
      return <DashboardScreen locale={locale} viewport={viewport} setScreen={setScreen} theme={theme} />;
    case "transactions":
      return <TransactionsScreen locale={locale} theme={theme} />;
    case "accounts":
      return <AccountsScreen locale={locale} theme={theme} />;
    case "budgets":
      return <BudgetsScreen locale={locale} theme={theme} />;
    case "goals":
      return <GoalsScreen locale={locale} theme={theme} />;
    case "inbox":
      return <InboxScreen locale={locale} theme={theme} />;
    case "settings":
      return <SettingsScreen locale={locale} setLocale={setLocale} setScreen={setScreen} theme={theme} />;
    case "addTx":
      return <AddTxScreen locale={locale} setScreen={setScreen} theme={theme} />;
    case "auth":
      return <AuthScreen locale={locale} setScreen={setScreen} theme={theme} />;
    case "family":
      return <FamilyScreen locale={locale} setScreen={setScreen} />;
    default:
      return null;
  }
}

export default function FamilyFinanceUiMock() {
  const theme = useHostTheme();
  const [viewport, setViewport] = useCanvasState<Viewport>("viewport", "mobile");
  const [screen, setScreen] = useCanvasState<Screen>("screen", "dashboard");
  const [locale, setLocale] = useCanvasState<Locale>("locale", "it");
  const t = copy[locale];

  return (
    <Stack gap={20} style={{ padding: 20, maxWidth: 1280, margin: "0 auto" }}>
      <Stack gap={6}>
        <H1 style={{ margin: 0 }}>{t.brand}</H1>
        <Text tone="secondary" style={{ margin: 0 }}>
          {locale === "it"
            ? "Mock interattivo UI/UX in stile Material 3 Expressive. Prova viewport, navigazione e lingua."
            : "Interactive UI/UX mock in Material 3 Expressive style. Try viewport, navigation, and language."}
        </Text>
      </Stack>

      <Row gap={8} wrap align="center">
        <Text size="small" tone="tertiary" style={{ margin: 0 }}>
          Viewport
        </Text>
        {(["mobile", "tablet", "wide"] as Viewport[]).map((v) => (
          <Button key={v} variant={viewport === v ? "primary" : "secondary"} onClick={() => setViewport(v)}>
            {v === "mobile" ? "Mobile" : v === "tablet" ? "Tablet" : "Wide"}
          </Button>
        ))}
        <Spacer />
        <Text size="small" tone="tertiary" style={{ margin: 0 }}>
          {t.language}
        </Text>
        <Button variant={locale === "it" ? "primary" : "secondary"} onClick={() => setLocale("it")}>
          IT
        </Button>
        <Button variant={locale === "en" ? "primary" : "secondary"} onClick={() => setLocale("en")}>
          EN
        </Button>
      </Row>

      <Row gap={6} wrap>
        {(
          [
            ["dashboard", t.dashboard],
            ["transactions", t.transactions],
            ["accounts", t.accounts],
            ["budgets", t.budgets],
            ["goals", t.goals],
            ["inbox", t.inbox],
            ["settings", t.settings],
            ["addTx", t.add],
            ["auth", t.signIn],
            ["family", t.createFamily],
          ] as const
        ).map(([id, label]) => (
          <Pill key={id} active={screen === id} onClick={() => setScreen(id)}>
            {label}
          </Pill>
        ))}
      </Row>

      <DeviceChrome viewport={viewport} theme={theme}>
        <AppShell viewport={viewport} screen={screen} setScreen={setScreen} locale={locale} theme={theme}>
          <ScreenBody
            screen={screen}
            setScreen={setScreen}
            locale={locale}
            setLocale={setLocale}
            viewport={viewport}
            theme={theme}
          />
        </AppShell>
      </DeviceChrome>

      <Stack gap={8}>
        <H2 style={{ margin: 0 }}>{locale === "it" ? "Principi M3 Expressive" : "M3 Expressive principles"}</H2>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
            gap: 12,
          }}
        >
          <Stack gap={4}>
            <Text weight="bold" style={{ margin: 0 }}>
              {locale === "it" ? "Forma e tensione" : "Shape & tension"}
            </Text>
            <Text size="small" tone="secondary" style={{ margin: 0 }}>
              {locale === "it"
                ? "Raggi grandi + silhouette asimmetriche (hero) accanto a chip full-round: contrasto senza rumore."
                : "Large radii + asymmetric hero silhouettes next to full-round chips — contrast without clutter."}
            </Text>
          </Stack>
          <Stack gap={4}>
            <Text weight="bold" style={{ margin: 0 }}>
              {locale === "it" ? "Tipografia enfatizzata" : "Emphasized type"}
            </Text>
            <Text size="small" tone="secondary" style={{ margin: 0 }}>
              {locale === "it"
                ? "Display sul saldo, titoli bold, importi più grandi nelle liste: guida lo sguardo al denaro."
                : "Display balance, bold titles, larger list amounts — attention follows the money."}
            </Text>
          </Stack>
          <Stack gap={4}>
            <Text weight="bold" style={{ margin: 0 }}>
              {locale === "it" ? "Contenimento" : "Containment"}
            </Text>
            <Text size="small" tone="secondary" style={{ margin: 0 }}>
              {locale === "it"
                ? "Superfici filled raggruppano grafici e liste; active indicator sulla nav bar/rail."
                : "Filled surfaces group charts and lists; active indicators on nav bar/rail."}
            </Text>
          </Stack>
          <Stack gap={4}>
            <Text weight="bold" style={{ margin: 0 }}>
              {locale === "it" ? "Navigazione per breakpoint" : "Breakpoint navigation"}
            </Text>
            <Text size="small" tone="secondary" style={{ margin: 0 }}>
              {locale === "it"
                ? "Mobile: nav bar + FAB. Tablet: item orizzontali. Wide: expanded rail con FAB in alto."
                : "Mobile: nav bar + FAB. Tablet: horizontal items. Wide: expanded rail with top FAB."}
            </Text>
          </Stack>
          <Stack gap={4}>
            <Text weight="bold" style={{ margin: 0 }}>
              {locale === "it" ? "Ingest da notifica" : "Notification ingest"}
            </Text>
            <Text size="small" tone="secondary" style={{ margin: 0 }}>
              {locale === "it"
                ? "Push → bozza Ingestion → avviso utente → conferma / modifica / scarta. Mai creazione silenziosa sul ledger."
                : "Push → Ingestion draft → user alert → confirm / edit / discard. Never silent ledger create."}
            </Text>
          </Stack>
        </div>
        <Text size="small" tone="quaternary" style={{ margin: 0 }}>
          {t.designNote}
        </Text>
      </Stack>
    </Stack>
  );
}
