struct FaviconImage: View {
    let link: String
    
    private var faviconURL: URL? {
        guard let url = URL(string: link),
              let host = url.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")
    }
    
    var body: some View {
        Group {
            if let faviconURL = faviconURL {
                CachedAsyncImage(url: faviconURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "globe")
                        .foregroundColor(.gray)
                }
                .frame(width: 16, height: 16)
            } else {
                Image(systemName: "globe")
                    .frame(width: 16, height: 16)
                    .foregroundColor(.gray)
            }
        }
    }
}