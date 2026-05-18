#!/usr/bin/env bash
# And I should visualize implementation progress as a roadmap
# Evidence: visual-dashboard skill exists for progress visualization; RELEASE_PLAN.md is the roadmap
if [ -d "visual-dashboard" ] && [ -f "specs/RELEASE-PLAN.md" ]; then
  exit 0
fi
echo "No visual-dashboard skill or RELEASE_PLAN.md roadmap found"
exit 1
