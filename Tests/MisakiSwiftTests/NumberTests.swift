import Foundation
import Testing
@testable import MisakiSwift

// Number reading, checked against an independent spelled-out reference (Foundation's .spellOut, en-US)
// phonemized through the same G2P. Both sides drop stress, spaces and punctuation, so a mismatch is a
// difference in the words spoken. An empty or unknown result is never a match.

private func spoken(_ g2p: EnglishG2P, _ text: String) -> String {
  let ps = g2p.phonemize(text: text).0
  return String(ps.unicodeScalars.filter { !"ˈˌː ,.;:!?—–-'\"()".unicodeScalars.contains($0) }.map(Character.init))
}

private func expectSameWords(_ g2p: EnglishG2P, _ text: String, _ reference: String,
                             sourceLocation: SourceLocation = #_sourceLocation) {
  let got = spoken(g2p, text), want = spoken(g2p, reference)
  #expect(!got.isEmpty && !want.isEmpty && !got.contains("❓"), "\(text): empty or unknown", sourceLocation: sourceLocation)
  #expect(got == want, "\(text) -> \(got), want \(reference) -> \(want)", sourceLocation: sourceLocation)
}

private let spellOut: NumberFormatter = {
  let f = NumberFormatter(); f.locale = Locale(identifier: "en_US"); f.numberStyle = .spellOut; return f
}()
private func words(_ n: Int) -> String { spellOut.string(from: NSNumber(value: n))! }

@Test func millionsReadAsMillions() async throws {
  let g2p = EnglishG2P(british: false)
  expectSameWords(g2p, "1,000,000", "one million")
  expectSameWords(g2p, "1000000", "one million")
  expectSameWords(g2p, "2,500,000", "two million five hundred thousand")
  for n in [1_000, 25_000, 100_000, 999_999] {
    expectSameWords(g2p, String(n), words(n))
  }
}

@Test func dollarAmountsReadAsWords() async throws {
  let g2p = EnglishG2P(british: false)
  for n in 1...100 {
    expectSameWords(g2p, "It cost $\(n).", "It cost \(words(n)) dollar\(n == 1 ? "" : "s").")
  }
  expectSameWords(g2p, "It cost $1500.", "It cost one thousand five hundred dollars.")
  expectSameWords(g2p, "room B35", "room B thirty-five")
}

@Test func dollarsAndCentsAreSpoken() async throws {
  let g2p = EnglishG2P(british: false)
  expectSameWords(g2p, "It cost $1.05.", "It cost one dollar and five cents.")
  expectSameWords(g2p, "It cost $25.50.", "It cost twenty-five dollars and fifty cents.")
  expectSameWords(g2p, "It cost $0.50.", "It cost fifty cents.")
  expectSameWords(g2p, "It cost $1.00.", "It cost one dollar.")
  expectSameWords(g2p, "It cost $1,250.", "It cost one thousand two hundred fifty dollars.")
  expectSameWords(g2p, "It was 3.5 miles.", "It was three point five miles.")
  // The symptom was silence, so check for the amount itself, not only agreement with the reference.
  for text in ["$1.05", "$25.50", "$0.50", "$1.00", "3.5"] {
    #expect(spoken(g2p, "It cost \(text) today.") != spoken(g2p, "It cost today."), "\(text) was silent")
  }
  // Abbreviations keep the letter path.
  expectSameWords(g2p, "the U.S. at 9 a.m.", "the U.S. at nine a.m.")
}

@Test func timesReadAsClockTimes() async throws {
  let g2p = EnglishG2P(british: false)
  expectSameWords(g2p, "at 1:00", "at one o'clock")
  expectSameWords(g2p, "at 1:05", "at one oh five")
  expectSameWords(g2p, "at 1:00 am", "at one a.m.")
  expectSameWords(g2p, "at 1:00 a.m.", "at one a.m.")
  expectSameWords(g2p, "at 1:00 pm", "at one p.m.")
  expectSameWords(g2p, "6:00 to 7:00", "six o'clock to seven o'clock")
  expectSameWords(g2p, "at 12:00", "at twelve o'clock")
  for m in 1...9 {
    expectSameWords(g2p, "at 3:0\(m)", "at three oh \(words(m))")
  }
  // am reads A.M. at every hour, spaced or not, never the verb; and a sentence-final one ends the sentence once.
  let aye = g2p.phonemize(text: "a.m.").0.filter { $0 != "." }
  for h in 1...12 {
    for form in ["\(h):00 am", "\(h):00am", "\(h):00 AM", "\(h):30am", "\(h):30 a.m."] {
      let ps = g2p.phonemize(text: "found at \(form) then").0
      #expect(ps.contains(aye), "\(form): \(ps)")
    }
    #expect(!g2p.phonemize(text: "found at \(h):30am.").0.contains(".."))
  }
  expectSameWords(g2p, "found at 4:30am.", "found at four thirty a.m.")
  // Minutes 10-59 keep their words.
  expectSameWords(g2p, "at 1:15", "at one fifteen")
  expectSameWords(g2p, "at 2:25", "at two twenty-five")
  expectSameWords(g2p, "at 1:40", "at one forty")
  // Not a time: a one-digit right side.
  #expect(g2p.phonemize(text: "odds of 10:1").0.contains(":"))
}
