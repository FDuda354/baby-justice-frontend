import SwiftUI
import PhotosUI
import Observation
import UIKit

@Observable
final class RewardFormModel {
    var name = ""
    var descriptionText = ""
    private(set) var costPoints = 10
    private(set) var costText = "10"
    var rewardType: RewardType = .oneTime
    var imageData: Data?
    var imageError: String?
    private(set) var hadExistingImage = false

    var previewImage: UIImage? {
        imageData.flatMap { UIImage(data: $0) }
    }

    var isValid: Bool {
        !trimmedName.isEmpty && costPoints > 0
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var removesExistingImage: Bool {
        hadExistingImage && imageData == nil
    }

    func prefill(with reward: RewardDTO) {
        name = reward.name
        descriptionText = reward.description
        costPoints = reward.costPoints
        costText = String(reward.costPoints)
        rewardType = reward.rewardType
        hadExistingImage = reward.hasImage
    }

    func loadExistingImage(_ data: Data) {
        applyPickedImage(data)
    }

    func updateCost(fromText text: String) {
        let digits = String(text.filter(\.isNumber).prefix(6))
        costText = digits
        costPoints = Int(digits) ?? 0
    }

    func updateCost(fromStepper value: Int) {
        costPoints = value
        costText = String(value)
    }

    func applyPickedImage(_ data: Data?) {
        guard let data, let processed = RewardImageProcessor.processedJpegData(from: data) else {
            imageError = "Nie udało się wczytać zdjęcia. Spróbuj wybrać inne."
            return
        }
        imageData = processed
        imageError = nil
    }

    func removeImage() {
        imageData = nil
        imageError = nil
    }

    func buildRequest() -> CreateRewardRequest {
        CreateRewardRequest(
            name: trimmedName,
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            costPoints: costPoints,
            rewardType: rewardType,
            imageBase64: imageData?.base64EncodedString(),
            imageContentType: imageData == nil ? nil : RewardImageProcessor.contentType,
            removeImage: removesExistingImage ? true : nil
        )
    }
}

struct RewardFormView: View {
    @Bindable var model: RewardFormModel

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: BJSpacing.l) {
            FormTextField(label: "Nazwa", text: $model.name)
            descriptionField
            costField
            typePicker
            photoSection
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                let data = try? await newItem.loadTransferable(type: Data.self)
                model.applyPickedImage(data)
                photoItem = nil
            }
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            fieldLabel("Opis")
            TextField("", text: $model.descriptionText, axis: .vertical)
                .lineLimit(3...6)
                .padding(BJSpacing.m)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
                .overlay(fieldBorder)
        }
    }

    private var costField: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            fieldLabel("Koszt (punkty)")
            HStack(spacing: BJSpacing.m) {
                TextField("", text: costTextBinding)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, BJSpacing.m)
                    .frame(height: BJSize.fieldHeight)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
                    .overlay(fieldBorder)
                Stepper("", value: costStepperBinding, in: 1...100000)
                    .labelsHidden()
            }
        }
    }

    private var costTextBinding: Binding<String> {
        Binding(
            get: { model.costText },
            set: { model.updateCost(fromText: $0) }
        )
    }

    private var costStepperBinding: Binding<Int> {
        Binding(
            get: { model.costPoints },
            set: { model.updateCost(fromStepper: $0) }
        )
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            fieldLabel("Typ nagrody")
            Picker("Typ nagrody", selection: $model.rewardType) {
                ForEach(RewardType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: BJSpacing.s) {
            fieldLabel("Zdjęcie (opcjonalnie)")
            if let previewImage = model.previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
            }
            HStack {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(model.imageData == nil ? "Wybierz zdjęcie" : "Zmień zdjęcie", systemImage: "photo")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.bjAccent)
                }
                if model.imageData != nil {
                    Spacer()
                    Button {
                        model.removeImage()
                    } label: {
                        Label("Usuń zdjęcie", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.bjDanger)
                    }
                }
            }
            if let imageError = model.imageError {
                Text(imageError)
                    .font(.caption)
                    .foregroundStyle(Color.bjDanger)
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous)
            .strokeBorder(Color.bjPrimary.opacity(0.2), lineWidth: 1)
    }
}
