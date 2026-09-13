# First release: article practice

## Goal

Help a learner associate a German noun with its definite article.

The initial release is an offline-first mobile app. It is deliberately limited to a single exercise type so that its learning flow, media handling, and physical-device behavior can be validated before further exercise types are added.

## Learner flow

For each question, the app:

1. Selects an article record from the bundled content.
2. Shows the noun and its image.
3. Lets the learner play the noun audio.
4. Presents exactly three choices: `der`, `die`, and `das`.
5. Shows whether the chosen answer is correct and presents the complete answer, such as `der Apfel`.
6. Lets the learner play the complete-answer audio.
7. Records the result locally and continues to the next question.

Audio should be available through an explicit play control. It should not automatically replay for every question.

## Content contract

The bundled source for this exercise is `assets/articles.json`. Each record has these properties:

| Property      | Purpose                                                    |
| ------------- | ---------------------------------------------------------- |
| `Id`          | Stable, unique content identifier                          |
| `Noun`        | German noun displayed to the learner                       |
| `Article`     | Correct definite article: `der`, `die`, or `das`           |
| `Category`    | Content grouping, initially for future selection/filtering |
| `Image`       | Bundled image asset path                                   |
| `Audio`       | Bundled noun-pronunciation asset path                      |
| `AnswerAudio` | Bundled complete-answer pronunciation asset path           |

The app must validate the content before use: every ID must be unique, every article must be one of the three supported values, and every referenced image and audio asset must exist. Asset paths in the JSON are the initial content contract and should not be reorganized without updating and revalidating the JSON.

## Content source and provenance

All imported assets were created by the project owner and copied from an earlier related project. The owner authorizes their bundling and redistribution with this app. This authorization covers images, noun audio, and answer audio; no external attribution, licence notice, or source-repository link is required.

The app bundles a local copy of approved resources and must not download learning assets at runtime.

## Local progress

The first release records completed and missed item IDs only on the device. It offers:

- a new/random practice session;
- a review session for previously missed items.

No account or cross-device synchronization is included.

## Out of scope

- Additional exercise types, including sentences and word recall.
- Accounts, authentication, backend services, and synchronization.
- Remote asset downloads.
- A generalized spaced-repetition scheduler.
- Social features, payments, analytics, and notifications.
- App Store publication.

## Acceptance criteria

- The app runs offline on at least one physical iOS or Android device.
- It supports a 10-question article-practice session using validated bundled content.
- The question image, noun audio, and answer audio work reliably.
- Correct and incorrect feedback is clear and displays the complete answer.
- Missed answers persist after the app is closed and can be practiced again.
- Automated tests cover JSON record mapping, content validation, and answer evaluation.

## Proposed working structure

When implementation starts, use this structure:

```text
assets/
  articles.json
  sentences.csv
  images/
  audio/
lib/
  app/
  content/
  domain/
  features/
    article_practice/
    progress/
  shared/
test/
  content/
  domain/
  features/
tool/
docs/
```

Keep content loading outside UI widgets, keep the article exercise isolated in `features/article_practice`, and add future exercise types as separate features.
