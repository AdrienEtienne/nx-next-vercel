#!/usr/bin/env bash
set -e

# echo $GH_TOKEN | gh auth login --with-token

echo "🔍 Recherche des champs du projet..."
FIELDS=$(gh api graphql -f query="
    {
        node(id: \"$PROJECT_ID\") {
            ... on ProjectV2 {
                fields(first: 20) {
                    nodes {
                        ... on ProjectV2SingleSelectField {
                            id
                            name
                            options {
                                id
                                name
                            }
                        }
                    }
                }
            }
        }
    }")
echo "✅ Champs trouvés: $(echo "$FIELDS" | jq -r '.data.node.fields.nodes[].name')"

FIELD_ID=$(echo "$FIELDS" | jq -r \
  --arg FIELD_NAME "$FIELD_NAME" '
    .data.node.fields.nodes[]
    | select(.name == $FIELD_NAME)
    | .id
')
if [ -z "$FIELD_ID" ]; then
  echo "❌ Champ introuvable"
  exit 1
fi
echo "✅ FIELD_ID = $FIELD_ID"

OPTION_ID=$(echo "$FIELDS" | jq -r \
  --arg FIELD_NAME "$FIELD_NAME" \
  --arg TARGET_OPTION "$TARGET_OPTION" '
    .data.node.fields.nodes[]
    | select(.name == $FIELD_NAME)
    | .options[]
    | select(.name == $TARGET_OPTION)
    | .id
')

if [ -z "$OPTION_ID" ]; then
  echo "❌ Option introuvable"
  exit 1
fi

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