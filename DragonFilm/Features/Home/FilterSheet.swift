import SwiftUI

/// Genre / country / type filter for the movie catalog.
struct CatalogFilter: Equatable {
    var kind: Kind = .latest
    var slug: String = ""
    var label: String = ""

    enum Kind: String, CaseIterable {
        case latest, type, genre, country

        var title: String {
            switch self {
            case .latest: return "Đề xuất"
            case .type: return "Loại phim"
            case .genre: return "Thể loại"
            case .country: return "Quốc gia"
            }
        }
    }

    var isEmpty: Bool { kind == .latest }
    var operation: String { kind == .latest ? "latest" : kind.rawValue }
    var displayTitle: String { label.isEmpty ? "Phim Mới Cập Nhật" : label }
}

struct FilterSheet: View {
    let selection: CatalogFilter
    var initialKind: CatalogFilter.Kind? = nil
    let onApply: (CatalogFilter) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind: CatalogFilter.Kind
    @State private var slug: String
    @State private var label: String

    init(selection: CatalogFilter, initialKind: CatalogFilter.Kind? = nil, onApply: @escaping (CatalogFilter) -> Void) {
        self.selection = selection
        self.initialKind = initialKind
        self.onApply = onApply
        _kind = State(initialValue: initialKind ?? (selection.kind == .latest ? .type : selection.kind))
        _slug = State(initialValue: selection.slug)
        _label = State(initialValue: selection.label)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DFSpacing.xxl) {
                    kindPicker

                    optionGrid
                }
                .padding(DFSpacing.xl)
            }
            .background(DFColor.bg)
            .navigationTitle("Bộ Lọc Phim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Xóa bộ lọc") {
                        onApply(CatalogFilter())
                        dismiss()
                    }
                    .font(DFFont.caption().bold())
                    .foregroundStyle(DFColor.textDim)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .font(DFFont.caption().bold())
                    .foregroundStyle(DFColor.gold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var kindPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DFSpacing.sm) {
                ForEach(CatalogFilter.Kind.allCases.filter { $0 != .latest }, id: \.rawValue) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            kind = item
                        }
                    } label: {
                        Text(item.title)
                            .font(DFFont.caption().bold())
                            .foregroundStyle(kind == item ? Color(hex: 0x07080A) : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(kind == item ? DFColor.gold : Color.white.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(kind == item ? Color.clear : Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var optionGrid: some View {
        VStack(alignment: .leading, spacing: DFSpacing.md) {
            Text(kind.title.uppercased())
                .font(DFFont.caption().bold())
                .foregroundStyle(DFColor.goldDim)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(options, id: \.slug) { option in
                    let isSelected = (selection.kind == kind && selection.slug == option.slug) || (slug == option.slug)
                    Button {
                        slug = option.slug
                        label = option.name
                        onApply(CatalogFilter(kind: kind, slug: option.slug, label: option.name))
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.name)
                                .font(DFFont.caption().bold())
                                .foregroundStyle(isSelected ? Color(hex: 0x07080A) : .white)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x07080A))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isSelected ? DFColor.gold : DFColor.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : DFColor.border.opacity(0.4), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var options: [CatalogOption] {
        switch kind {
        case .latest: return []
        case .genre: return CatalogOption.genres
        case .country: return CatalogOption.countries
        case .type: return CatalogOption.types
        }
    }
}

struct CatalogOption {
    let name: String
    let slug: String

    static let genres: [CatalogOption] = [
        .init(name: "Hành Động", slug: "hanh-dong"),
        .init(name: "Tình Cảm", slug: "tinh-cam"),
        .init(name: "Hài Hước", slug: "hai-huoc"),
        .init(name: "Cổ Trang", slug: "co-trang"),
        .init(name: "Tâm Lý", slug: "tam-ly"),
        .init(name: "Hình Sự", slug: "hinh-su"),
        .init(name: "Chiến Tranh", slug: "chien-tranh"),
        .init(name: "Thể Thao", slug: "the-thao"),
        .init(name: "Võ Thuật", slug: "vo-thuat"),
        .init(name: "Viễn Tưởng", slug: "vien-tuong"),
        .init(name: "Phiêu Lưu", slug: "phieu-luu"),
        .init(name: "Khoa Học", slug: "khoa-hoc"),
        .init(name: "Kinh Dị", slug: "kinh-di"),
        .init(name: "Âm Nhạc", slug: "am-nhac"),
        .init(name: "Thần Thoại", slug: "than-thoai"),
        .init(name: "Gia Đình", slug: "gia-dinh"),
        .init(name: "Học Đường", slug: "hoc-duong"),
        .init(name: "Kinh Điển", slug: "kinh-dien")
    ]

    static let countries: [CatalogOption] = [
        .init(name: "Việt Nam", slug: "viet-nam"),
        .init(name: "Trung Quốc", slug: "trung-quoc"),
        .init(name: "Hàn Quốc", slug: "han-quoc"),
        .init(name: "Nhật Bản", slug: "nhat-ban"),
        .init(name: "Thái Lan", slug: "thai-lan"),
        .init(name: "Âu Mỹ", slug: "au-my"),
        .init(name: "Đài Loan", slug: "dai-loan"),
        .init(name: "Hồng Kông", slug: "hong-kong"),
        .init(name: "Ấn Độ", slug: "an-do"),
        .init(name: "Anh", slug: "anh"),
        .init(name: "Pháp", slug: "phap"),
        .init(name: "Nga", slug: "nga")
    ]

    static let types: [CatalogOption] = [
        .init(name: "Phim Lẻ", slug: "phim-le"),
        .init(name: "Phim Bộ", slug: "phim-bo"),
        .init(name: "Hoạt Hình", slug: "hoat-hinh"),
        .init(name: "TV Shows", slug: "tv-shows")
    ]
}
