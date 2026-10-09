import Foundation

/// The kitty's entire personality, organized by mood tier.
///
/// Placeholders available in any message:
///   {task}    – the task the kitty is nagging about
///   {count}   – number of open tasks
///   {overdue} – number of overdue tasks
///   {streak}  – current streak in days
///
/// Edit these strings to retrain your cat. That's the whole API.
public enum MessageBank {
    public static let happy: [String] = [
        "look at you GO! i'm doing a little dance. you can't see it but it's happening",
        "i'm so proud i could purr. actually i am purring. loudly.",
        "{streak} days of you being amazing. i made you a sticker chart. you earned ALL of them",
        "you finished your stuff so i napped in a sunbeam on your behalf. team effort",
        "we are SO back. best human award. it's not even close",
        "zero overdue tasks. zero. i checked twice because i didn't believe it",
        "this is my favorite version of you and i've seen ALL of them",
        "productivity level: chef's kiss. now go rest, i'll guard the streak"
    ]

    public static let content: [String] = [
        "hey. you're doing fine. just saying",
        "nice work so far. {count} thing{plural} left and then we both relax",
        "i believe in you. casually. like it's not a big deal. (it's a big deal to me)",
        "next up: {task}. small steps. i'll wait, i'm a cat",
        "the streak is at {streak}. no pressure. okay some pressure",
        "progress looks good on you. keep it up and i'll keep the sunbeam warm",
        "you and me. we chip away. that's the whole plan",
        "everything is fine and i am calmly monitoring the situation"
    ]

    public static let uneasy: [String] = [
        "um. {overdue} task{plural} slipped past. should we... talk about it?",
        "i'm not mad. i'm just sitting here. facing you. with the list",
        "{task} was due. it's not due anymore. it's OVERdue. words matter",
        "you okay? because the list is starting to give me anxiety and i'm a cat",
        "i practiced my disappointed sigh. want to hear it? *sigh*",
        "the tasks are piling up and i am small. please handle {task}",
        "i don't want to be dramatic but the streak is {streak} and i'd like to keep it",
        "gentle reminder that i can see the calendar. cats see everything"
    ]

    public static let grumpy: [String] = [
        "{overdue} overdue. bold strategy. how's it working out",
        "i knocked your imaginary pencil off the imaginary desk. this is your fault",
        "still scrolling? fascinating. tell me more about your plans to not do {task}",
        "i had a whole speech ready but you'd just ignore it like the notifications",
        "the streak was {streak}. WAS. past tense. i'm past tense about it",
        "i'm not doing the cute ears today. the cute ears are CANCELED",
        "you know what? do whatever. i'll just sit here. being ignored. again",
        "one star. woulddelegate productivity to this human again. wait. i can't. you're the only one"
    ]

    public static let furious: [String] = [
        "{overdue}. OVERDUE. i have listed the tasks. i have listed them TWICE",
        "i'm peeing in your productivity shoes. metaphorically. probably",
        "every minute you scroll, one of my whiskers falls out. think about it",
        "the goose would have dragged your windows around by now. be grateful i'm a cat",
        "i'm not speaking to you. this message was scheduled. even my RESENTMENT is automated",
        "your streak is a memory now. i keep the receipts. i keep ALL the receipts",
        "i have seen the truth: the tasks were never real to you. but they were real to ME",
        "when future you looks back at today, will they see {task} done? NO. they will see NOTHING"
    ]

    /// Reminder-style titles by tier (used for notifications).
    public static let titles: [MoodTier: [String]] = [
        .happy: ["happy kitty", "good news", "small victory report"],
        .content: ["kitty check-in", "psst", "friendly nudge"],
        .uneasy: ["kitty is worried", "um... it's due", "gentle alarm"],
        .grumpy: ["the kitty is unimpressed", "it's due. it's due NOW", "official complaint"],
        .furious: ["THE KITTY DEMANDS ACTION", "final warning (not final, but still)", "extra furious hour"]
    ]

    public static func messages(for tier: MoodTier) -> [String] {
        switch tier {
        case .happy: return happy
        case .content: return content
        case .uneasy: return uneasy
        case .grumpy: return grumpy
        case .furious: return furious
        }
    }
}
