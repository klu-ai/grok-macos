//
//  Embedding.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages the collection of text embedding models used for semantic search,
//  text similarity, and natural language understanding tasks. This component
//  provides access to various embedding models optimized for different use cases.
//
//  Model providers:
//  - Snowflake (Arctic series)
//  - BAAI (BGE series)
//  - IBM (Granite series)
//  - MixedBread.ai
//  - Nomic
//
//  Key features:
//  - Multilingual support
//  - Various model sizes (30M to 335M parameters)
//  - Optimized for different tasks
//  - Balance between performance and resource usage
//
//  Usage notes:
//  - Access through EmbeddingModels.available
//  - Models range from lightweight to full-featured
//  - Select based on language requirements
//  - Consider memory and performance tradeoffs

import Foundation

/// Provider of text embedding models
public struct EmbeddingModels {
    /// Available embedding models
    public static let available: [Model] = [
        Model(name: "snowflake-arctic-embed2", displayName: "Snowflake Arctic Embed 2", lab: "Snowflake", sizeInGB: 0.6, description: "Latest Snowflake model with multilingual support", gguf: "https://huggingface.co/lmstudiocommunity/snowflake-arctic-embed2-gguf", mlx: "https://ollama.com/directory/snowflake-arctic-embed2-mlx"),
        Model(name: "bge-m3", displayName: "BGE M3", lab: "BAAI", sizeInGB: 0.3, description: "BAAI's versatile multilingual model", gguf: "https://huggingface.co/lmstudiocommunity/bge-m3-gguf", mlx: "https://ollama.com/directory/bge-m3-mlx"),
        Model(name: "mxbai-embed-large", displayName: "MxBai Embed Large", lab: "MixedBread.ai", sizeInGB: 0.17, description: "MixedBread.ai's large model", gguf: "https://huggingface.co/lmstudiocommunity/mxbai-embed-large-gguf", mlx: "https://ollama.com/directory/mxbai-embed-large-mlx"),
        Model(name: "granite-embedding-278m", displayName: "Granite Embedding 278M", lab: "IBM", sizeInGB: 0.14, description: "IBM's multilingual model", gguf: "https://huggingface.co/lmstudiocommunity/granite-embedding-278m-gguf", mlx: "https://ollama.com/directory/granite-embedding-278m-mlx"),
        Model(name: "bge-large", displayName: "BGE Large", lab: "BAAI", sizeInGB: 0.17, description: "BAAI's English model", gguf: "https://huggingface.co/lmstudiocommunity/bge-large-gguf", mlx: "https://ollama.com/directory/bge-large-mlx"),
        Model(name: "snowflake-arctic-embed-335m", displayName: "Snowflake Arctic Embed 335M", lab: "Snowflake", sizeInGB: 0.17, description: "Snowflake's medium model", gguf: "https://huggingface.co/lmstudiocommunity/snowflake-arctic-embed-335m-gguf", mlx: "https://ollama.com/directory/snowflake-arctic-embed-335m-mlx"),
        Model(name: "paraphrase-multilingual", displayName: "Paraphrase Multilingual", lab: "Sentence Transformers", sizeInGB: 0.14, description: "Sentence transformers model", gguf: "https://huggingface.co/lmstudiocommunity/paraphrase-multilingual-gguf", mlx: "https://ollama.com/directory/paraphrase-multilingual-mlx"),
        Model(name: "nomic-embed-text", displayName: "Nomic Embed Text", lab: "Nomic", sizeInGB: 0.008, description: "High-performing with large context", gguf: "https://huggingface.co/lmstudiocommunity/nomic-embed-text-gguf", mlx: "https://ollama.com/directory/nomic-embed-text-mlx"),
        Model(name: "granite-embedding-30m", displayName: "Granite Embedding 30M", lab: "IBM", sizeInGB: 0.015, description: "IBM's English-only model", gguf: "https://huggingface.co/lmstudiocommunity/granite-embedding-30m-gguf", mlx: "https://ollama.com/directory/granite-embedding-30m-mlx"),
        Model(name: "all-minilm-33m", displayName: "All-MiniLM 33M", lab: "Microsoft", sizeInGB: 0.017, description: "Efficient small model", gguf: "https://huggingface.co/lmstudiocommunity/all-minilm-33m-gguf", mlx: "https://ollama.com/directory/all-minilm-33m-mlx")
    ]
    
    /// Default embedding model name
    public static let defaultModel = "nomic-embed-text"
}
