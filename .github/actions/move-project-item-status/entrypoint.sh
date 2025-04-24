#!/usr/bin/env bash
set -e

echo "🔍 Recherche des champs du projet..."
FIELDS=$(gh api graphql -f query='
  {
    node(id: "PVT_kwHOAC2He84A3YmW") {
        ... on ProjectV2 {
            fields(first: 20) {
                nodes {
                    ... on ProjectV2SingleSelectField {
                        options {
                            id
                            name
                        }
                    }
                }
            }
        }
    }
    }')

FIELD_ID=$(echo "$FIELDS" | jq -r \
  --arg FIELD_NAME "$FIELD_NAME" '
    .data.node.fields.nodes[]
    | select(.name == $FIELD_NAME)
    | .id
')

OPTION_ID=$(echo "$FIELDS" | jq -r \
  --arg FIELD_NAME "$FIELD_NAME" \
  --arg TARGET_OPTION "$TARGET_OPTION" '
    .data.node.fields.nodes[]
    | select(.name == $FIELD_NAME)
    | .options[]
    | select(.name == $TARGET_OPTION)
    | .id
')

if [ -z "$FIELD_ID" ] || [ -z "$OPTION_ID" ]; then
  echo "❌ Champ ou option introuvable"
  exit 1
fi

echo "✅ FIELD_ID = $FIELD_ID"
echo "✅ OPTION_ID = $OPTION_ID"

echo "➡️ Mise à jour de l’item..."
gh api graphql -f query="
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: \"$PROJECT_ID\",
      itemId: \"$ITEM_ID\",
      fieldId: \"$FIELD_ID\",
      value: {
        singleSelectOptionId: \"$OPTION_ID\"
      }
    }) {
      projectV2Item {
        id
      }
    }
  }"

echo "success=true" >> $GITHUB_OUTPUT