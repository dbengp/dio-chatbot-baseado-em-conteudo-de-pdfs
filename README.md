# dio-chatbot-baseado-em-conteudo-de-pdfs
- o projeto visa criar um chat interativo que responderá com base no conteúdo dos seus arquivos PDF. Para isso, utilizaremos conceitos de IA generativa, embeddings e buscas vetorizadas para estruturar um sistema capaz de entender, processar e responder perguntas a partir de documentos.

## Solução Provisionada com Terraform: 
- Esta solução provisiona a infraestrutura essencial no Azure para construir o seu chat interativo baseado em PDFs, utilizando os serviços de armazenamento, busca cognitiva e IA generativa da OpenAI, além de uma opção para hospedar a aplicação do chat.
- Grupo de Recursos (azurerm_resource_group): Organiza todos os recursos relacionados ao projeto.
- Conta de Armazenamento (azurerm_storage_account e azurerm_storage_container): Armazena os arquivos PDF que serão processados.
- Azure Cognitive Search Service (azurerm_cognitive_search_service): Indexa os embeddings gerados a partir do conteúdo dos PDFs, permitindo buscas semânticas eficientes.
- Azure Machine Learning Workspace (azurerm_machine_learning_workspace): Embora não estritamente necessário para a execução do chat, o AML Workspace é útil para o desenvolvimento, experimentação e gerenciamento do processo de geração de embeddings e potencialmente para o deploy de modelos personalizados no futuro.
- Azure OpenAI Service Account (azurerm_cognitive_account): Provisiona o acesso aos modelos de linguagem da OpenAI no Azure.
- Azure OpenAI Service Deployments (azurerm_cognitive_deployment): Cria implantações específicas dos modelos text-embedding-ada-002 (para gerar embeddings) e gpt-35-turbo (para gerar respostas no chat).
- Azure Container Instances (azurerm_container_group - Opcional, mas recomendado para um exemplo completo): Provisiona um contêiner para hospedar a aplicação do chat interativo.
  * image: Você precisará substituir "seu-registro-docker/sua-imagem-chat-app:latest" pela sua própria imagem Docker da aplicação de chat. Esta aplicação conterá a lógica para:
    * Receber a pergunta do usuário.
    * Gerar o embedding da pergunta usando a API do Azure OpenAI Service.
    * Consultar o Azure Cognitive Search usando o embedding da pergunta para encontrar os trechos de texto relevantes dos PDFs.
    * Enviar a pergunta e os trechos relevantes para o modelo de completação do Azure OpenAI Service para gerar a resposta.
    * Retornar a resposta ao usuário.
  * environment_variables: Passa informações de conexão e nomes de recursos para a aplicação do chat dentro do contêiner.
  * depends_on: Garante que os serviços de Cognitive Search e OpenAI estejam provisionados antes de tentar criar o grupo de contêineres.
- Após o Provisionamento com Terraform):
  * Carregar os PDFs: Faça o upload dos seus arquivos PDF para o container na conta de armazenamento.
  * Desenvolver a Aplicação do Chat: Crie a aplicação (em Python, Node.js, etc.) que implementa a lógica de processamento, geração de embeddings, busca e geração de respostas, conforme descrito no item 7 da explicação acima.
  * Criar a Imagem Docker da Aplicação: Empacote sua aplicação em um contêiner Docker.
  * Enviar a Imagem Docker para um Registro de Contêineres: Envie a imagem para o Azure Container Registry (ACR) ou outro registro de contêineres acessível pelo ACI.
  * Atualizar a Imagem no Terraform: Substitua o placeholder da imagem no recurso azurerm_container_group.
  * Aplicar o Terraform (novamente): Para criar o grupo de contêineres com a sua aplicação de chat.
  * Interagir com o Chat: Acesse o endereço IP público do seu grupo de contêineres (fornecido na saída do Terraform ou no portal do Azure) para interagir com o chat.
