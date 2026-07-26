// story: e80s05
// Positive fixture: IDOR / missing tenant scoping (must be flagged).
//
// Modelled on the bigbase family (BUG-129/130/133/135/136/140/143): the
// handler authenticates the caller, then trusts an ID from the request and
// queries by that ID alone. Authentication is proven; authorization is not.
// Nothing in the type system or a diff-scoped review makes this look wrong —
// the bug is a predicate that was never written.
package fixtures

import (
	"database/sql"
	"net/http"
)

func handleGetSitePositive(w http.ResponseWriter, r *http.Request, db *sql.DB) {
	siteID := r.URL.Query().Get("site_id")

	// VULNERABLE: scoped by primary key only. Any authenticated caller from any
	// organization can read any site by guessing or enumerating site_id.
	row := db.QueryRow(`SELECT id, name, domain FROM sites WHERE id = ?`, siteID)

	var id, name, domain string
	if err := row.Scan(&id, &name, &domain); err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	_, _ = w.Write([]byte(name + " " + domain))
}
