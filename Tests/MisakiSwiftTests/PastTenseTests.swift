import Testing
@testable import MisakiSwift

// An -ied past that isn't in the lexicon is read from its -y stem, as stem_s reads -ies. "copied" is in
// neither us_gold nor us_silver, and fell through to the guesser as kˈOpid.

@Test func anIedPastIsReadFromItsYStem() async throws {
  let g2p = EnglishG2P(british: false)
  #expect(g2p.phonemize(text: "copied").0 == "kˈɑpid")
  #expect(g2p.phonemize(text: "At six she copied the reserve page for me.").0.contains(" kˈɑpid "))
  #expect(g2p.phonemize(text: "Copied it.").0.hasPrefix("kˈɑpid "))
  // In capitals, getWord lowercases a word stem_ed can read, so this was spelled out letter by letter.
  #expect(g2p.phonemize(text: "COPIED").0 == "kˈɑpid")
  // Each is the stem's own phonemes plus d.
  for word in ["copied", "palsied", "lilied"] {
    let stem = String(word.dropLast(3)) + "y"
    #expect(g2p.phonemize(text: word).0 == g2p.phonemize(text: stem).0 + "d", "\(word)")
  }
  // Unchanged: -ied words the lexicon has.
  for (word, ps) in [("carried", "kˈɛɹid"), ("studied", "stˈʌdid"), ("supplied", "səplˈId")] {
    #expect(g2p.phonemize(text: word).0 == ps, "\(word)")
  }
}
