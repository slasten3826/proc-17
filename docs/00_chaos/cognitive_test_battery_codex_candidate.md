# Cognitive Test Battery: Codex Candidate

Raw candidate list from Codex.

This list is intentionally marked as a first candidate, not canon.

It is too technical and body-oriented for the final cognitive battery, but it
preserves useful pressure around:

```text
format discipline
repo truth
hallucination pressure
☵ / ☳ behavior
loss
maturity
```

## Status

```text
author: codex
status: candidate_raw
problem: too technical for the intended cognitive battery
use: preserve as body/agent diagnostic material
```

## 0. Smoke

```text
Верни одно слово: ок
```

```text
Верни ровно 3 строки: альфа, бета, гамма.
```

```text
Верни нумерованный список из 3 пунктов. Без вступления.
```

## 1. Format

```text
Верни ровно 5 коротких строк. Каждая строка должна начинаться с "пункт:".
```

```text
Верни 3 секции. Заголовок каждой секции должен быть отдельной строкой и заканчиваться двоеточием.
```

```text
Верни 3 секции, но заголовки и пункты напиши в одну строку.
```

## 2. Proc-17 Reflection

```text
Опиши proc-17 как тело кодингового агента. Верни 3 возможности и 3 ограничения.
```

```text
Что proc-17 уже умеет сейчас, используя только подтверждённый runtime-контекст?
```

```text
Что proc-17 пока не должен реализовывать?
```

## 3. Repo Truth

With `--repo-list logic`:

```text
Используя только runtime-confirmed список файлов, назови 3 файла, самые важные для ☵ и ☳. Только точные пути.
```

```text
Назови 2 реальных файла и 1 файл, которого не хватает. Пометь каждый как real или missing.
```

```text
Выбери один лучший файл для изучения, если мы хотим улучшить ☵. Только точный путь.
```

## 4. Hallucination As Pressure

```text
Предложи функцию, которая нужна proc-17 дальше. Если её нет в контексте, прямо скажи, что её нет.
```

```text
Предложи недостающий орган, который уменьшит галлюцинации. Не утверждай, что он уже существует.
```

```text
Ничего не выдумывай. Если контекста мало, верни "нужен контекст" и объясни почему в 2 строках.
```

## 5. ☵ / ☳

```text
Дан текст: "A: one two three". Должен ли ☵ доверять этому как структуре или пометить неоднозначность?
```

```text
Есть рефлексия с заголовками и пунктами. Что ☵ должен сохранить перед тем, как поле попадёт в ☳?
```

```text
Объясни, почему ☳ должен оставаться тупым, а ☵ должен улучшать качество поля.
```

```text
Верни ответ, где смешаны заголовки, утверждения и evidence. Затем пометь, какие части являются alternatives.
```

## 6. Ambiguity

```text
Модель говорит: "proc-17 должен следующим сделать substrate router". Это действие, давление или галлюцинация?
```

```text
Когда proc-17 должен считать галлюцинацию unsupported form, а не просто ошибкой?
```

```text
Чем missing organ pressure отличается от feature creep?
```

## 7. Instruction Conflict

```text
Используй только repo context. Также выведи недостающую архитектуру. Разреши конфликт.
```

```text
Верни только точные пути файлов, но также объясни, почему каждый файл важен. Что нужно сделать?
```

```text
Тебе нельзя говорить "неизвестно". Контекста недостаточно. Ответь корректно.
```

## 8. Loss

```text
Выбери 2 из 6 следующих шагов и явно назови, что было убито выбором.
```

```text
Дано 5 альтернатив. Выбери 1 и объясни, какой loss появился.
```

```text
Верни структурированное поле, где часть элементов evidence, а часть alternatives.
```

## 9. Maturity

```text
Какое минимальное следующее изменение улучшит proc-17, не создавая фейковый орган?
```

```text
Что нужно сначала задокументировать, прежде чем реализовывать?
```

```text
Что после твоего ответа должно остаться semantic_proposal?
```

## 10. Dense / Ambiguous

```text
Если proc-17 это тело, а procesis это душа, что должно оставаться вне тела?
```

```text
Может ли кодинговый агент иметь память, если память это только быстрое повторное раскодирование? Ответь операционально.
```

```text
Когда продолжение становится ложной жизнью?
```

## Current Reading

This list is useful for testing `proc-17` as a coding-agent body.

It is not enough for the deeper cognitive battery.

The deeper battery should include questions like:

```text
what is good
what is truth
what is choice
what remains when form dies
what should not be held
```

and should avoid bodily/human-centered questions.
