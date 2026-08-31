import json
import re
from pathlib import Path

import yaml


PROJECT_ROOT = Path(__file__).resolve().parent.parent
KINGDOMS_DIR = PROJECT_ROOT / "kingdoms"
CARDS_DIR = PROJECT_ROOT / "assets" / "cards"
OUTPUT_FILE = PROJECT_ROOT / "assets" / "sets" / "official_sets.json"


# Use the current/second-edition recommended sets where available.
KINGDOM_FILES = [
    "base-set-2.yaml",
    "intrigue-2.yaml",
    "seaside-2.yaml",
    "prosperity-2.yaml",
    "hinterlands-2.yaml",
    "guildscornucopia2.yaml",

    "alchemy.yaml",
    "dark-ages.yaml",
    "adventures.yaml",
    "empires.yaml",
    "nocturne.yaml",
    "renaissance.yaml",
    "menagerie.yaml",
    "allies.yaml",
    "plunder.yaml",
    "risingsun.yaml",
]


# KingdomCreator prefix -> set name used by your Dominion card JSON.
SET_ALIASES = {
    "baseset": "Base",
    "baseset2": "Base",

    "intrigue": "Intrigue",
    "intrigue2": "Intrigue",

    "seaside": "Seaside",
    "seaside2": "Seaside",

    "alchemy": "Alchemy",

    "prosperity": "Prosperity",
    "prosperity2": "Prosperity",

    "cornucopia": "Cornucopia & Guilds",
    "guilds": "Cornucopia & Guilds",
    "guildscornucopia2": "Cornucopia & Guilds",

    "hinterlands": "Hinterlands",
    "hinterlands2": "Hinterlands",

    "darkages": "Dark Ages",
    "adventures": "Adventures",
    "empires": "Empires",
    "nocturne": "Nocturne",
    "renaissance": "Renaissance",
    "menagerie": "Menagerie",
    "allies": "Allies",
    "plunder": "Plunder",
    "risingsun": "Rising Sun",
}

DISPLAY_EXPANSION_ALIASES = {
    "baseset": "Base (1E)",
    "baseset2": "Base (2E)",

    "intrigue": "Intrigue (1E)",
    "intrigue2": "Intrigue (2E)",

    "seaside": "Seaside (1E)",
    "seaside2": "Seaside (2E)",

    "prosperity": "Prosperity (1E)",
    "prosperity2": "Prosperity (2E)",

    "hinterlands": "Hinterlands (1E)",
    "hinterlands2": "Hinterlands (2E)",

    "cornucopia": "Cornucopia",
    "guilds": "Guilds",
    "guildscornucopia2": "Cornucopia & Guilds (2E)",

    "alchemy": "Alchemy",
    "darkages": "Dark Ages",
    "adventures": "Adventures",
    "empires": "Empires",
    "nocturne": "Nocturne",
    "renaissance": "Renaissance",
    "menagerie": "Menagerie",
    "allies": "Allies",
    "plunder": "Plunder",
    "risingsun": "Rising Sun",
}

# When a second-edition YAML file refers to its own expansion
# using the old source token, display it as the second edition.
FILE_EXPANSION_OVERRIDES = {
    "base-set-2.yaml": {
        "baseset": "Base (2E)",
        "baseset2": "Base (2E)",
    },
    "intrigue-2.yaml": {
        "intrigue": "Intrigue (2E)",
        "intrigue2": "Intrigue (2E)",
    },
    "seaside-2.yaml": {
        "seaside": "Seaside (2E)",
        "seaside2": "Seaside (2E)",
    },
    "prosperity-2.yaml": {
        "prosperity": "Prosperity (2E)",
        "prosperity2": "Prosperity (2E)",
    },
    "hinterlands-2.yaml": {
        "hinterlands": "Hinterlands (2E)",
        "hinterlands2": "Hinterlands (2E)",
    },
    "guildscornucopia2.yaml": {
        "cornucopia": "Cornucopia & Guilds (2E)",
        "guilds": "Cornucopia & Guilds (2E)",
        "guildscornucopia2": "Cornucopia & Guilds (2E)",
    },
}


# Prefixes KingdomCreator inserts between the expansion and card name.
CARD_TYPE_PREFIXES = {
    "event",
    "landmark",
    "project",
    "way",
    "ally",
    "prophecy",
    "trait",
}


def normalize(text: str) -> str:
    """
    Converts:
        Catapult/Rocks       -> catapultrocks
        Farmer's Market      -> farmersmarket
        Will-o'-Wisp         -> willowisp
    """
    return re.sub(r"[^a-z0-9]", "", text.lower())


def load_cards():
    cards = []

    for path in sorted(CARDS_DIR.glob("*.json")):
        with path.open("r", encoding="utf-8") as file:
            data = json.load(file)

        if isinstance(data, list):
            cards.extend(data)
        elif isinstance(data, dict):
            # Allows for a wrapper object if one of your JSON files uses one.
            if "cards" in data:
                cards.extend(data["cards"])

    return cards


def build_card_lookup(cards):
    """
    Lookup:
        (normalized set, normalized card name) -> app card ID

    Example:
        ("empires", "catapultrocks")
            -> "Empires::Catapult/Rocks"
    """
    lookup = {}

    for card in cards:
        name = card["name"]
        set_name = card["set"]

        key = (
            normalize(set_name),
            normalize(name),
        )

        lookup[key] = f"{set_name}::{name}"

    return lookup


def split_kingdom_creator_id(source_id: str):
    """
    Example:
        empires_event_wedding
            -> ("empires", "wedding")

        empires_catapultrocks
            -> ("empires", "catapultrocks")

        baseset2_cellar
            -> ("baseset2", "cellar")
    """
    parts = source_id.split("_")

    if len(parts) < 2:
        raise ValueError(
            f"Unexpected KingdomCreator ID: {source_id}"
        )

    source_set = parts[0]
    remainder = parts[1:]

    if remainder and remainder[0] in CARD_TYPE_PREFIXES:
        remainder = remainder[1:]

    card_name = "".join(remainder)

    return source_set, normalize(card_name)


def resolve_card_id(source_id, card_lookup):
    source_set, normalized_name = split_kingdom_creator_id(
        source_id
    )

    app_set = SET_ALIASES.get(source_set)

    if app_set is None:
        return None

    # KingdomCreator prefixes Boons with "boon_",
    # while our card data uses only the Boon name.
    if source_set == "nocturne" and normalized_name.startswith("boon"):
        normalized_name = normalized_name.removeprefix("boon")

    key = (
        normalize(app_set),
        normalized_name,
    )

    return card_lookup.get(key)


def resolve_list(
    source_ids,
    card_lookup,
    unresolved,
    set_name,
    field_name,
):
    result = []

    for source_id in source_ids or []:
        resolved = resolve_card_id(
            source_id,
            card_lookup,
        )

        if resolved is None:
            unresolved.append({
                "recommendedSet": set_name,
                "field": field_name,
                "sourceId": source_id,
            })
            continue

        result.append(resolved)

    return result


def display_expansion(source_set, filename):
    file_overrides = FILE_EXPANSION_OVERRIDES.get(
        filename,
        {},
    )

    if source_set in file_overrides:
        return file_overrides[source_set]

    if source_set in DISPLAY_EXPANSION_ALIASES:
        return DISPLAY_EXPANSION_ALIASES[source_set]

    return source_set


def main():
    cards = load_cards()
    card_lookup = build_card_lookup(cards)

    print(f"Loaded {len(cards)} Dominion cards.")

    output_sets = []
    unresolved = []

    for filename in KINGDOM_FILES:
        path = KINGDOMS_DIR / filename

        if not path.exists():
            print(f"WARNING: Missing {path}")
            continue

        with path.open("r", encoding="utf-8") as file:
            data = yaml.safe_load(file)

        kingdoms = data.get("kingdoms", [])

        print(
            f"{filename}: {len(kingdoms)} recommended sets"
        )

        for kingdom in kingdoms:
            name = kingdom["name"]

            kingdom_cards = resolve_list(
                kingdom.get("supply", []),
                card_lookup,
                unresolved,
                name,
                "supply",
            )

            extras = []

            for field in [
                "events",
                "landmarks",
                "projects",
                "ways",
                "allies",
                "prophecies",
                "boons",
            ]:
                extras.extend(
                    resolve_list(
                        kingdom.get(field, []),
                        card_lookup,
                        unresolved,
                        name,
                        field,
                    )
                )

            traits = []

            for trait_entry in kingdom.get("traits", []) or []:
                if "->" not in trait_entry:
                    unresolved.append({
                        "recommendedSet": name,
                        "field": "traits",
                        "sourceId": trait_entry,
                    })
                    continue

                trait_source_id, target_source_id = trait_entry.split(
                    "->",
                    1,
                )

                trait_card_id = resolve_card_id(
                    trait_source_id,
                    card_lookup,
                )

                target_card_id = resolve_card_id(
                    target_source_id,
                    card_lookup,
                )

                if trait_card_id is None or target_card_id is None:
                    unresolved.append({
                        "recommendedSet": name,
                        "field": "traits",
                        "sourceId": trait_entry,
                    })
                    continue

                traits.append({
                    "traitCardId": trait_card_id,
                    "targetCardId": target_card_id,
                })

            expansions = [
                display_expansion(value, filename)
                for value in kingdom.get("sets", [])
            ]

            result = {
                "name": name,
                "expansions": expansions,
                "kingdomCardIds": kingdom_cards,
                "extraCardIds": extras,
                "traits": traits,
            }

            #
            # Preserve special setup information which isn't
            # represented by a normal card.
            #
            notes = []

            if "bane" in kingdom:
                bane = resolve_card_id(
                    kingdom["bane"],
                    card_lookup,
                )

                if bane is not None:
                    notes.append(
                        f"Bane: {bane.split('::', 1)[1]}"
                    )
                else:
                    unresolved.append({
                        "recommendedSet": name,
                        "field": "bane",
                        "sourceId": kingdom["bane"],
                    })

            if "obeliskActionCard" in kingdom:
                obelisk = resolve_card_id(
                    kingdom["obeliskActionCard"],
                    card_lookup,
                )

                if obelisk is not None:
                    notes.append(
                        "Obelisk pile: "
                        + obelisk.split("::", 1)[1]
                    )
                else:
                    unresolved.append({
                        "recommendedSet": name,
                        "field": "obeliskActionCard",
                        "sourceId":
                            kingdom["obeliskActionCard"],
                    })

            metadata = kingdom.get("metadata", {})

            if metadata.get("colonies"):
                notes.append(
                    "Use Platinum and Colony."
                )

            if metadata.get("shelters"):
                notes.append(
                    "Use Shelters."
                )

            if notes:
                result["note"] = "\n".join(notes)

            output_sets.append(result)

        # Remove recommended sets repeated across expansion rulebooks.
    unique_sets = []
    seen_sets = set()

    for recommended_set in output_sets:
        key = (
            recommended_set["name"],
            tuple(sorted(recommended_set["expansions"])),
        )

        if key in seen_sets:
            continue

        seen_sets.add(key)
        unique_sets.append(recommended_set)

    output_sets = unique_sets

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with OUTPUT_FILE.open(
        "w",
        encoding="utf-8",
    ) as file:
        json.dump(
            output_sets,
            file,
            indent=2,
            ensure_ascii=False,
        )

    print()
    print(
        f"Wrote {len(output_sets)} recommended sets to:"
    )
    print(OUTPUT_FILE)

    print()

    if unresolved:
        print(
            f"UNRESOLVED CARD IDs: {len(unresolved)}"
        )
        print()

        for item in unresolved:
            print(
                f"{item['recommendedSet']} "
                f"[{item['field']}]: "
                f"{item['sourceId']}"
            )

        print()
        print(
            "The JSON was generated, but resolve these "
            "entries before considering the import complete."
        )
    else:
        print(
            "Success: every referenced card was resolved."
        )


if __name__ == "__main__":
    main()