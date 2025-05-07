import random

# --- Define Components for Prompt Generation ---

subjects = [
    "men's silver wristwatch with a blue face",
    "standard blue European Union passport",
    "set of house keys on a simple silver keyring",
    "modern black smartphone (screen off)",
    "crumpled white paper receipt",
    "pair of black-rimmed eyeglasses",
    "brown leather wallet",
    "single white wireless earbud",
    "credit card (generic design, numbers obscured/fake)",
    "folded warranty card for electronics",
]

angles = [
    "front view",
    "back view",
    "left side view",
    "right side view",
    "top-down view",
    "45-degree angle view",
    "slightly angled top-down view",
    # Add subject-specific angles if needed
    "open to the photo page (for passport)",
    "open showing card slots (for wallet)",
]

framing_percentages = ["70%", "80%", "85%", "90%"]

# Staging options - divided for clarity
isolated_staging = [
    "resting flat on a clean, plain white surface",
    "placed on a simple light-colored wooden tabletop",
    "lying on a neutral grey fabric cloth",
    "on a plain black matte background",
    "on a slightly textured white paper sheet",
]

contextual_staging = [
    "held steadily in a person's hand against a softly blurred neutral background",
    "worn on a person's wrist against a simple shirt sleeve (for watch)",
    "placed on a car dashboard (for keys/phone)",
    "sitting on a clean kitchen counter",
    "partially emerging from a pocket (for wallet/phone)",
]

# Combine staging types
all_staging = isolated_staging + contextual_staging

# --- Prompt Template Functions ---


def generate_standard_prompt(subject, angle, framing, staging):
    """Generates a prompt using the detailed standard template."""
    return f"""
Generate an image simulating a raw evidence record captured by a user with a smartphone (like an iPhone) for an app.

**Subject:** A single {subject}.
**View/Angle:** The image shows the subject from a clear {angle}.
**Framing & Composition:** The subject is the primary focus, sharply in focus, well-lit, and fills approximately {framing} of the vertical frame. Ensure the entire object is visible if feasible for the angle.
**Style & Quality:** Realistic photograph style, resembling an unedited snapshot taken with a modern smartphone camera. No filters, artistic stylization, or heavy processing. The image should be clear enough to be suitable for machine learning analysis.
**Orientation:** Portrait mode (vertical aspect ratio).
**Staging & Background:** The subject is {staging}. The background should be simple and not distract from the subject.
**Context:** This simulates a user capturing an item for identification or categorization within an application.
---
"""


def generate_simplified_prompt(subject, angle, staging):
    """Generates a prompt using a more concise template."""
    return f"""
Realistic smartphone photo, portrait orientation, of a {subject}. Angle: {angle}. The subject fills most of the frame and is the clear focus. Background: {staging}. Raw, unedited style suitable for ML analysis. No filters.
---
"""


def generate_contextual_prompt(subject, angle, framing, staging):
    """Generates a prompt specifically for contextual 'hero' shots."""
    # Ensure the staging is appropriate for contextual
    if staging not in contextual_staging:
        staging = random.choice(
            contextual_staging
        )  # Pick a suitable one if not provided

    return f"""
Generate an image simulating a user's 'hero shot' evidence record using a smartphone.

**Subject:** A single {subject}.
**View/Angle:** Clear {angle}.
**Framing:** The subject is the main focus, sharply detailed, filling about {framing} of the vertical frame.
**Style:** Realistic, unedited photo quality, portrait mode. Looks like a good quality phone snapshot.
**Staging:** The subject is {staging}. The background is softly blurred but contextually relevant and non-distracting. Focus remains firmly on the subject. Suitable for ML analysis despite the contextual background.
---
"""


# --- Generation Logic ---


def generate_prompts(
    num_prompts_per_type=5, use_standard=True, use_simplified=True, use_contextual=True
):
    """Generates a mix of prompts using different templates."""
    generated_prompts = []

    # Generate Standard Prompts
    if use_standard:
        print("--- Generating Standard Prompts ---")
        for i in range(num_prompts_per_type):
            subject = random.choice(subjects)
            angle = random.choice(angles)
            # Filter out incompatible angles/subjects if necessary (e.g., 'open page' for a watch)
            if ("(for passport)" in angle and "passport" not in subject) or (
                "(for wallet)" in angle and "wallet" not in subject
            ):
                angle = random.choice(
                    [a for a in angles if "(for" not in a]
                )  # Pick a generic angle

            framing = random.choice(framing_percentages)
            staging = random.choice(isolated_staging)  # Standard usually uses isolated
            prompt = generate_standard_prompt(subject, angle, framing, staging)
            generated_prompts.append(prompt)
            print(f"Standard Prompt {i+1}:\n{prompt}")

    # Generate Simplified Prompts
    if use_simplified:
        print("\n--- Generating Simplified Prompts ---")
        for i in range(num_prompts_per_type):
            subject = random.choice(subjects)
            angle = random.choice(angles)
            if ("(for passport)" in angle and "passport" not in subject) or (
                "(for wallet)" in angle and "wallet" not in subject
            ):
                angle = random.choice([a for a in angles if "(for" not in a])

            # Simplified often uses isolated, but can vary
            staging = random.choice(
                isolated_staging + contextual_staging[:2]
            )  # Mix in some simple context
            prompt = generate_simplified_prompt(subject, angle, staging)
            generated_prompts.append(prompt)
            print(f"Simplified Prompt {i+1}:\n{prompt}")

    # Generate Contextual Prompts
    if use_contextual:
        print("\n--- Generating Contextual Prompts ---")
        for i in range(num_prompts_per_type):
            subject = random.choice(subjects)
            # Contextual often benefits from more dynamic angles
            angle = random.choice(
                [a for a in angles if "view" in a and "top-down" not in a]
            )  # Avoid flat top-down
            if ("(for passport)" in angle and "passport" not in subject) or (
                "(for wallet)" in angle and "wallet" not in subject
            ):
                angle = random.choice([a for a in angles if "(for" not in a])

            framing = random.choice(
                framing_percentages[:-1]
            )  # Slightly less framing maybe
            staging = random.choice(contextual_staging)  # Must use contextual
            # Ensure subject makes sense for staging (e.g., watch on wrist)
            if "wrist" in staging and "watch" not in subject:
                subject = random.choice(
                    [s for s in subjects if "watch" in s]
                )  # Force watch if wrist staging
            elif "pocket" in staging and ("keys" in subject or "earbud" in subject):
                subject = random.choice(
                    [s for s in subjects if "wallet" in s or "phone" in s]
                )  # Force wallet/phone if pocket

            prompt = generate_contextual_prompt(subject, angle, framing, staging)
            generated_prompts.append(prompt)
            print(f"Contextual Prompt {i+1}:\n{prompt}")

    return generated_prompts


# --- Main Execution ---
if __name__ == "__main__":
    # Configure how many prompts of each type to generate
    num_each = 5
    print(f"Generating {num_each} prompts for each selected type...\n")

    all_prompts = generate_prompts(
        num_prompts_per_type=num_each,
        use_standard=True,
        use_simplified=True,
        use_contextual=True,
    )

    print(f"\n--- Total Prompts Generated: {len(all_prompts)} ---")

    # You can optionally save these prompts to a file
    # with open("generated_prompts.txt", "w") as f:
    #     for prompt in all_prompts:
    #         f.write(prompt + "\n")
    # print("\nPrompts saved to generated_prompts.txt")
