// story: e80s05
// Negative fixture: correctly scoped tenant query (must NOT be flagged).
//
// The org comes from the authenticated context, never from the request, and it
// is part of the WHERE clause. A caller from another organization gets zero
// rows rather than someone else's site.
//
// Note the retrofit trap this deliberately avoids: bigbase's BUG-2026-07-24T184443
// added `org_id INTEGER NOT NULL DEFAULT 0`, which passed tests on new rows and
// hid 8 of 9 production sites whose legacy rows defaulted to org 0. Scope on a
// real, backfilled org_id — never a placeholder default.
package fixtures

import (
	"database/sql"
	"net/http"
)

func orgIDFromContext(r *http.Request) (string, bool) {
	v, ok := r.Context().Value(ctxOrgID).(string)
	return v, ok && v != ""
}

type ctxKey string

const ctxOrgID ctxKey = "org_id"

func handleGetSiteNegative(w http.ResponseWriter, r *http.Request, db *sql.DB) {
	orgID, ok := orgIDFromContext(r)
	if !ok {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	siteID := r.URL.Query().Get("site_id")

	// SAFE: the tenant predicate is not optional and does not come from input.
	row := db.QueryRow(
		`SELECT id, name, domain FROM sites WHERE id = ? AND org_id = ?`,
		siteID, orgID,
	)

	var id, name, domain string
	if err := row.Scan(&id, &name, &domain); err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	_, _ = w.Write([]byte(name + " " + domain))
}
