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
