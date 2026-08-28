import SwiftUI

/// Genre / country / type filter for the "Phim Mới Cập Nhật" grid. Slugs match
/// the upstream taxonomy the web client uses.
struct CatalogFilter: Equatable {
    var kind: Kind = .latest
    var slug: String = ""
    var label: String = ""

    enum Kind: String, CaseIterable {
        case latest, genre, country, type

        var title: String {
            switch self {
            case .latest: return "Mới nhất"
            case .genre: return "Thể loại"
            case .country: return "Quốc gia"
            case .type: return "Loại phim"
            }
        }
    }

    var isEmpty: Bool { kind == .latest }
    var operation: String { kind == .latest ? "latest" : kind.rawValue }
    var displayTitle: String { label.isEmpty ? "Phim Mới Cập Nhật" : label }
}

struct FilterSheet: View {
    let selection: CatalogFilter
    let onApply: (CatalogFilter) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind: CatalogFilter.Kind
    @State private var slug: String
    @State private var label: String

    init(selection: CatalogFilter, onApply: @escaping (CatalogFilter) -> Void) {
        self.selection = selection
        self.onApply = onApply
        _kind = State(initialValue: selection.kind)
        _slug = State(initialValue: selection.slug)
        _label = State(initialValue: selection.label)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DFSpacing.xxl) {
                    kindPicker

                    if kind != .latest {
                        optionGrid
                    }
                }
                .padding(DFSpacing.xxl)
            }
            .background(DFColor.bg)
            .navigationTitle("Bộ lọc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Xóa lọc") {
                        onApply(CatalogFilter())
                        dismiss()
                    }
                    .foregroundStyle(DFColor.textDim)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Áp dụng") {
                        onApply(CatalogFilter(kind: kind, slug: slug, label: label))
                        dismiss()
                    }
                    .foregroundStyle(DFColor.gold)
                    .disabled(kind != .latest && slug.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: DFSpacing.md) {
            Text("KIỂU LỌC")
                .font(DFFont.small())
                .foregroundStyle(DFColor.textMuted)
            HStack(spacing: DFSpacing.md) {
                ForEach(CatalogFilter.Kind.allCases, id: \.rawValue) { item in
                    Button {
                        kind = item
                        slug = ""
                        label = ""
                    } label: {
                        Text(item.title)
                            .font(DFFont.caption())
                            .foregroundStyle(kind == item ? DFColor.bg : DFColor.textDim)
                            .padding(.horizontal, DFSpacing.lg)
                            .padding(.vertical, DFSpacing.md)
                            .background(kind == item ? DFColor.gold : DFColor.bg3)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var optionGrid: some View {
        VStack(alignment: .leading, spacing: DFSpacing.md) {
            Text(kind.title.uppercased())
                .font(DFFont.small())
                .foregroundStyle(DFColor.textMuted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DFSpacing.md), count: 2),
                      spacing: DFSpacing.md) {
                ForEach(options, id: \.slug) { option in
                    Button {
                        slug = option.slug
                        label = option.name
                    } label: {
                        Text(option.name)
                            .font(DFFont.caption())
                            .foregroundStyle(slug == option.slug ? DFColor.bg : DFColor.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DFSpacing.lg)
                            .background(slug == option.slug ? DFColor.gold : DFColor.bg3)
                            .clipShape(RoundedRectangle(cornerRadius: DFRadius.md))
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
