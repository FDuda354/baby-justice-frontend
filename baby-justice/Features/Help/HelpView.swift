import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BJSpacing.xl) {
                introCard
                familySection
                tasksSection
                rewardsSection
                tipCard
            }
            .padding(BJSpacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Jak korzystać z aplikacji")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                HStack(spacing: BJSpacing.s) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.bjAmber)
                    Text("Jak to działa?")
                        .font(.headline)
                }
                Text("Dzieci robią zadania, zbierają punkty i wymieniają je na nagrody. Rodzic tworzy zadania, sprawdza je i prowadzi sklep z nagrodami. Poniżej znajdziesz wszystko krok po kroku.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var familySection: some View {
        HelpSectionView(
            icon: "figure.2.and.child.holdinghands",
            title: "Jak założyć rodzinę",
            steps: [
                HelpStep(
                    icon: "person.badge.plus",
                    title: "Rodzic zakłada konto",
                    text: "Rodzic rejestruje się w aplikacji i nadaje rodzinie nazwę. W ten sposób powstaje Wasza rodzina."
                ),
                HelpStep(
                    icon: "person.crop.circle.badge.plus",
                    title: "Dziecko zakłada własne konto",
                    text: "Dziecko rejestruje się samo — podaje swój e-mail i hasło. Po rejestracji dostaje swój własny kod dziecka."
                ),
                HelpStep(
                    icon: "123.rectangle.fill",
                    title: "Kod łączy Was w rodzinę",
                    text: "Dziecko podaje kod rodzicowi. Rodzic wpisuje go w zakładce Dzieci i od tej chwili dziecko należy do rodziny."
                )
            ]
        )
    }

    private var tasksSection: some View {
        HelpSectionView(
            icon: "checklist",
            title: "Zadania i punkty",
            steps: [
                HelpStep(
                    icon: "square.and.pencil",
                    title: "Rodzic tworzy zadania",
                    text: "Rodzic dodaje zadanie i ustala, ile punktów można za nie dostać. Zadanie może być wspólne dla wszystkich albo przypisane jednemu dziecku, jednorazowe albo powtarzalne."
                ),
                HelpStep(
                    icon: "hand.tap.fill",
                    title: "Dziecko bierze zadanie",
                    text: "Dziecko wybiera zadanie z listy dostępnych i bierze je dla siebie."
                ),
                HelpStep(
                    icon: "checkmark.circle.fill",
                    title: "Zrobione? Oznacz!",
                    text: "Gdy zadanie jest skończone, dziecko oznacza je jako wykonane i czeka na decyzję rodzica."
                ),
                HelpStep(
                    icon: "checkmark.seal.fill",
                    title: "Rodzic sprawdza",
                    text: "Jeśli rodzic zaakceptuje zadanie, punkty od razu trafiają na konto dziecka. Jeśli je odrzuci, podaje powód, a zadanie wraca na listę — można spróbować jeszcze raz."
                ),
                HelpStep(
                    icon: "star.circle.fill",
                    iconColor: .bjAmber,
                    title: "Punkty od rodzica",
                    text: "Rodzic może też ręcznie dodać lub odjąć punkty — zawsze z opisem, żeby było wiadomo, za co."
                )
            ]
        )
    }

    private var rewardsSection: some View {
        HelpSectionView(
            icon: "gift.fill",
            title: "Nagrody",
            steps: [
                HelpStep(
                    icon: "storefront.fill",
                    title: "Rodzic prowadzi sklep",
                    text: "Każde dziecko ma swój własny sklep. Rodzic dodaje do niego nagrody i ustala ich cenę w punktach."
                ),
                HelpStep(
                    icon: "cart.fill",
                    title: "Dziecko kupuje nagrodę",
                    text: "Dziecko wymienia zebrane punkty na wybraną nagrodę ze swojego sklepu."
                ),
                HelpStep(
                    icon: "shippingbox.fill",
                    title: "Rodzic wydaje nagrodę",
                    text: "Rodzic przekazuje nagrodę dziecku i oznacza ją w aplikacji jako wydaną."
                ),
                HelpStep(
                    icon: "party.popper.fill",
                    title: "Dziecko potwierdza odbiór",
                    text: "Na koniec dziecko potwierdza, że nagroda do niego dotarła. I można zbierać punkty na kolejną!"
                )
            ]
        )
    }

    private var tipCard: some View {
        CardView {
            HStack(alignment: .top, spacing: BJSpacing.m) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.bjAmber)
                Text("Wskazówka: powiadomienia w aplikacji dadzą Ci znać, gdy wydarzy się coś ważnego — na przykład gdy zadanie zostanie zaliczone albo nagroda będzie gotowa do odbioru.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HelpStep {
    let icon: String
    var iconColor: Color = .bjPrimary
    let title: String
    let text: String
}

private struct HelpSectionView: View {
    let icon: String
    let title: String
    let steps: [HelpStep]

    var body: some View {
        VStack(alignment: .leading, spacing: BJSpacing.m) {
            HStack(spacing: BJSpacing.s) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bjAccent)
                    .frame(width: 32, height: 32)
                    .background(Color.bjMint)
                    .clipShape(RoundedRectangle(cornerRadius: BJRadius.small, style: .continuous))
                Text(title)
                    .font(.title3.bold())
            }
            CardView {
                VStack(alignment: .leading, spacing: BJSpacing.l) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HelpStepRow(number: index + 1, step: step)
                        if index < steps.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private struct HelpStepRow: View {
    let number: Int
    let step: HelpStep

    var body: some View {
        HStack(alignment: .top, spacing: BJSpacing.m) {
            Image(systemName: step.icon)
                .font(.headline)
                .foregroundStyle(step.iconColor)
                .frame(width: 36, height: 36)
                .background(step.iconColor.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: BJSpacing.xs) {
                Text("\(number). \(step.title)")
                    .font(.subheadline.weight(.semibold))
                Text(step.text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
