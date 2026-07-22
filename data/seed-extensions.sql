-- Netresearch Extensions Demo Pages
-- Imported on first boot to showcase Netresearch TYPO3 extensions

-- Parent page: "Extensions" in main navigation
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, is_siteroot, backend_layout, sorting, hidden, deleted)
VALUES (101, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Extensions', '/extensions', 1, 0, '', 525, 0, 0);

-- =============================================================================
-- RTE CKEditor Image
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (102, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'RTE CKEditor Image', '/extensions/rte-ckeditor-image', 1, 100, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (400, 102, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'RTE CKEditor Image',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(47,153,164,0.06), rgba(47,153,164,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.7rem;">CKEditor</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Open Source</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Advanced Image Handling for CKEditor 5</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Block images, inline images, click-to-enlarge, and linked images — all directly in the TYPO3 rich text editor. No content elements needed.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-rte_ckeditor_image" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://extensions.typo3.org/extension/rte_ckeditor_image" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">TER</a>
    <a href="https://packagist.org/packages/netresearch/rte-ckeditor-image" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body text-center py-4">
        <h6 class="fw-bold" style="font-size: 0.88rem;">Block Images</h6>
        <p class="text-muted mb-0" style="font-size: 0.78rem;">Standalone images with captions and alignment. Processed as TYPO3 images with responsive srcset.</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body text-center py-4">
        <h6 class="fw-bold" style="font-size: 0.88rem;">Inline Images</h6>
        <p class="text-muted mb-0" style="font-size: 0.78rem;">Images that flow naturally within text — icons, logos, and small illustrations inline with content.</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body text-center py-4">
        <h6 class="fw-bold" style="font-size: 0.88rem;">Click-to-Enlarge</h6>
        <p class="text-muted mb-0" style="font-size: 0.78rem;">Lightbox popup via <code>data-htmlarea-zoom</code>. Click any image to view full resolution.</p>
      </div>
    </div>
  </div>
</div>

<h2 class="fw-bold mb-3" style="font-size: 1.2rem;">Live Demos</h2>

<h3 class="fw-bold mb-2" style="font-size: 1rem;">Block Image</h3>
<p class="text-muted mb-2" style="font-size: 0.88rem;">A standalone image inserted via CKEditor — rendered with responsive srcset:</p>
<p><img src="/fileadmin/user_upload/images/Home/CH5_7354.jpg" alt="Team photo demo" width="800" data-htmlarea-file-uid="190" data-htmlarea-file-table="sys_file"></p>

<h3 class="fw-bold mb-2 mt-4" style="font-size: 1rem;">Inline Image in Text</h3>
<p style="font-size: 0.88rem;">Text can contain inline images like this <img class="image image-inline" src="/fileadmin/user_upload/images/netresearch-typo3-demo.png" alt="inline logo" width="60" data-htmlarea-file-uid="1" data-htmlarea-file-table="sys_file"> logo that flows naturally within the paragraph.</p>

<div class="alert alert-light border mt-4" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #2F99A4;">For integrators:</strong> Edit this page in the TYPO3 backend to see the CKEditor image toolbar button in action. All images above are inserted via CKEditor, not the standard image content element.
</div>',
0, 100, 0, 0);

-- Click-to-Enlarge (Lightbox) live demo — relocated out of the CType=html block
-- above into a regular CType=text element so its rich text runs through
-- lib.parseFunc_RTE. Only then does rte_ckeditor_image convert the
-- data-htmlarea-zoom image into a click-to-enlarge (zoom popup) link; inside a
-- raw html element parseFunc_RTE never runs and the img stays bare.
-- Free uid above the base-dump tt_content max (522).
INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (601, 102, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Click-to-Enlarge (Lightbox) — Live Demo',
'<p class="text-muted mb-2" style="font-size: 0.88rem;">Click the image below to see the zoom popup. Because this is a regular Text element, its rich text is processed by <code>lib.parseFunc_RTE</code>, so rte_ckeditor_image turns the <code>data-htmlarea-zoom</code> image into a click-to-enlarge link:</p>
<p><img src="/fileadmin/user_upload/images/Home/CH5_7203.jpg" alt="Click to enlarge" width="400" data-htmlarea-file-uid="188" data-htmlarea-file-table="sys_file" data-htmlarea-zoom="true"></p>',
0, 150, 0, 0);

-- =============================================================================
-- AI Cowriter
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (103, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'AI Cowriter', '/extensions/cowriter', 1, 200, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (401, 103, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'AI Cowriter',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(47,153,164,0.06), rgba(47,153,164,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.7rem;">AI</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">CKEditor Plugin</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">AI-Powered Content Assistant</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Select text in CKEditor and let AI rewrite, summarize, translate, or fix grammar. Configurable tasks with custom prompts.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-cowriter" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/t3-cowriter" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Rewrite &amp; Rephrase</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Change tone from formal to casual, simplify complex text, or rephrase for clarity — all without leaving the editor.</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Summarize &amp; Extend</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Condense long articles into key points, or expand bullet points into full paragraphs with context.</p>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Translate &amp; Fix</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Translate between languages or fix grammar and spelling mistakes. Custom tasks with configurable prompts.</p>
      </div>
    </div>
  </div>
</div>

<div class="rounded-3 p-3 mb-4" style="background: #f8f9fa;">
  <h5 class="fw-bold mb-3" style="font-size: 0.95rem;">How it works</h5>
  <div class="d-flex flex-column gap-2">
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">1</span>
      <span style="font-size: 0.84rem;">Configure an LLM provider in the <a href="/extensions/nr-llm/" style="color: #2F99A4;">NR LLM</a> backend module</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">2</span>
      <span style="font-size: 0.84rem;">Select text in CKEditor and click the Cowriter toolbar button</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">3</span>
      <span style="font-size: 0.84rem;">Choose a task (Rewrite, Summarize, Translate, etc.) or write a custom prompt</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #FF4D00;">4</span>
      <span style="font-size: 0.84rem;">Review the AI suggestion and apply it with one click</span>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #2F99A4;">Try it:</strong> Edit this page in the TYPO3 backend to see the Cowriter button in the CKEditor toolbar.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- NR LLM
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (104, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'LLM Foundation', '/extensions/nr-llm', 1, 300, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (402, 104, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'NR LLM — AI Foundation for TYPO3',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(88,89,97,0.06), rgba(88,89,97,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #585961; font-size: 0.7rem;">Core</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Foundation</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">One LLM Setup for Every Extension</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">The shared AI foundation for TYPO3. Configure providers, models, and task templates once — every AI extension on your site uses them.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-llm" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #585961;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-llm" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #585961;">Provider Management</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Configure Ollama, OpenAI, Anthropic, Google, or custom API endpoints. Switch providers without touching extension code.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #585961;">Model Registry</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Manage available models with temperature, token limits, and context window settings. Assign models to specific tasks.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #585961;">Task Templates</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Reusable prompt templates shared across extensions. Define system prompts, output formats, and constraints once.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #585961;">Backend Module</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Visual management of all LLM resources under Admin Tools &gt; LLM. Test prompts, monitor usage, configure profiles.</p>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #585961;">Powers:</strong> <a href="/extensions/cowriter/" style="color: #2F99A4;">AI Cowriter</a> and <a href="/extensions/landing-page/" style="color: #2F99A4;">Landing Page Generator</a> both use NR LLM for their AI capabilities.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Landing Page Generator
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (105, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Landing Page Generator', '/extensions/landing-page', 1, 400, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (403, 105, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'AI Landing Page Generator',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(47,153,164,0.06), rgba(47,153,164,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.7rem;">AI</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Backend Wizard</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Generate Landing Pages with AI</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Describe your goal and let AI create a complete, structured TYPO3 page with hero, features, content sections, and call-to-action.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/nr-landingpage" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-landingpage" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Structured Output</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">AI generates real TYPO3 content elements — hero sections, feature grids, text blocks, and contact forms. Not just text blobs.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Backend Wizard</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Visual wizard under Web &gt; Landing Pages. Enter your brief, choose a template, review the result, and publish.</p>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #2F99A4;">Requires:</strong> <a href="/extensions/nr-llm/" style="color: #2F99A4;">NR LLM</a> with a configured provider. Access the wizard in the TYPO3 backend under Web &gt; Landing Pages.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Passkeys Backend
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (106, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Passkeys (Backend)', '/extensions/passkeys-be', 1, 500, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (404, 106, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'Passwordless Backend Login with Passkeys',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(255,77,0,0.04), rgba(255,77,0,0.01));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.7rem;">Security</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">WebAuthn</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Passwordless Backend Login</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">WebAuthn/FIDO2 passkey authentication for TYPO3 backend users. Replace passwords with fingerprint, face recognition, or security keys.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-passkeys-be" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #FF4D00;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-passkeys-be" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Per-Group Enforcement</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Four levels: <strong>Off</strong>, <strong>Encourage</strong> (nudge on login), <strong>Required</strong> (grace period), <strong>Enforced</strong> (immediate). Configure per backend user group.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Adoption Dashboard</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Track passkey rollout across all backend users. See who has registered, who needs nudging, and overall adoption rates.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Multi-Device Support</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Register passkeys on laptop, phone, and security keys. Manage all credentials under User Settings &gt; Passkeys.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Interstitial Prompts</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Configurable enrollment prompts after password login. Encourage adoption gradually or enforce immediately.</p>
      </div>
    </div>
  </div>
</div>

<p class="text-muted" style="font-size: 0.82rem;">See also: <a href="/extensions/passkeys-fe/" style="color: #2F99A4; font-weight: 600;">Passkeys (Frontend)</a> for frontend user authentication.</p>',
0, 100, 0, 0);

-- =============================================================================
-- Passkeys Frontend
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (109, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Passkeys (Frontend)', '/extensions/passkeys-fe', 1, 510, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (407, 109, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'Passkey-First Frontend Authentication',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(255,77,0,0.04), rgba(255,77,0,0.01));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.7rem;">Security</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">WebAuthn</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Passkey-First Frontend Authentication</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">WebAuthn/FIDO2 passkey login for TYPO3 frontend users. Replace passwords with biometrics — fingerprint, face recognition, or security keys.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="/login" class="btn btn-sm text-white" style="background: #FF4D00;">Try Live Demo</a>
    <a href="https://github.com/netresearch/t3x-nr-passkeys-fe" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-passkeys-fe" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Passkey-First Login</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Tabbed felogin override: Passkey tab is default, password tab as fallback. Discoverable credentials via browser autofill.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Management Plugin</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Frontend plugin for users to register, rename, and remove passkeys. Recovery codes for account access if all keys are lost.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Zero Template Work</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Drop-in felogin override. Passkey tab, management UI, and enrollment prompts work out of the box. No Fluid templates to write.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Recovery Codes</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">One-time recovery codes for account access if all passkeys are lost. Generate, download, and manage via frontend UI.</p>
      </div>
    </div>
  </div>
</div>

<div class="rounded-3 p-3 mb-4" style="background: #f8f9fa;">
  <h5 class="fw-bold mb-3" style="font-size: 0.95rem;">How it works</h5>
  <div class="d-flex flex-column gap-2">
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">1</span>
      <span style="font-size: 0.84rem;"><code>composer require netresearch/nr-passkeys-fe</code></span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">2</span>
      <span style="font-size: 0.84rem;">Add the passkey management plugin to a protected page</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #2F99A4;">3</span>
      <span style="font-size: 0.84rem;">Felogin gets a passkey tab automatically — users see biometric login first</span>
    </div>
    <div class="d-flex align-items-start gap-2">
      <span class="badge rounded-circle text-white flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; font-size: 0.7rem; background: #FF4D00;">4</span>
      <span style="font-size: 0.84rem;">Users register passkeys and log in with fingerprint, face, or security key</span>
    </div>
  </div>
</div>

<p class="text-muted" style="font-size: 0.82rem;">See also: <a href="/extensions/passkeys-be/" style="color: #2F99A4; font-weight: 600;">Passkeys (Backend)</a> for backend user authentication.</p>',
0, 100, 0, 0);

-- =============================================================================
-- Secrets Vault
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (107, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Secrets Vault', '/extensions/vault', 1, 600, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (405, 107, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'NR Vault — Secure Secrets Management',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(255,77,0,0.04), rgba(255,77,0,0.01));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.7rem;">Security</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Enterprise</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Enterprise Secrets Management</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Envelope encryption, access control, audit logging, and key rotation for TYPO3. Stop storing API keys in plain text.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-vault" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #FF4D00;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-vault" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Envelope Encryption</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Each secret encrypted with its own data key, wrapped by a master key. Industry-standard envelope encryption pattern.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Access Control</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Scope secrets to extensions, backend user groups, or environments. Granular permissions for who can read what.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">CLI &amp; Backend Module</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;"><code>vault:init</code>, <code>vault:store</code>, <code>vault:retrieve</code>, <code>vault:rotate</code> — manage secrets via CLI or the visual backend module.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Audit &amp; Rotation</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Full audit trail of who accessed which secret and when. Rotate master keys without re-encrypting all secrets.</p>
      </div>
    </div>
  </div>
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Temporal Cache
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (108, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Temporal Cache', '/extensions/temporal-cache', 1, 700, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (406, 108, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'Automatic Cache Invalidation for Timed Content',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(88,89,97,0.06), rgba(88,89,97,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #585961; font-size: 0.7rem;">Cache</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Performance</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Timed Content, Automatic Cache</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Solves <a href="https://forge.typo3.org/issues/14277" target="_blank" rel="noopener" style="color: #2F99A4;">TYPO3 Forge #14277</a>: content with start/end times stays cached beyond its visibility window. This extension fixes that — automatically.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-temporal-cache" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #585961;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-temporal-cache" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Automatic Invalidation</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Cache clears precisely when content becomes visible or expires. No more stale pages showing hidden content.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem;">Flexible Scoping</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Invalidate single pages, page trees, or all pages. Scheduler-based or on-demand cache clearing strategies.</p>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #585961;">Zero config:</strong> Works transparently with all content types that use TYPO3 starttime/endtime fields. Install and forget.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- AI Chat Agent
-- =============================================================================
-- uid 157 (not 110): the base dump (data/db.sql.gz) already has pages up to
-- uid 156, so uid 110 collided with an existing page and INSERT IGNORE skipped
-- it (404). tt_content uid 522 is likewise above the base dump's max (521).
-- Remove any stray content from the earlier mis-seed (uid 408 attached to the
-- pre-existing page 110) so it does not linger on that page.
DELETE FROM tt_content WHERE uid = 408 AND pid = 110 AND CType = 'html';

INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (157, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'AI Chat Agent', '/extensions/ai-agent', 1, 800, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (522, 157, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'Conversational AI in the TYPO3 Backend',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(47,153,164,0.06), rgba(47,153,164,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.7rem;">AI</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">MCP</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">Chat With Your TYPO3 Install</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">An AI assistant embedded in the TYPO3 backend. Ask about pages, content, users, logs, and site configuration — the agent reads and acts on the live system through MCP tools.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-mcp-agent" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-mcp-agent" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Tool-Grounded Answers</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Every response is grounded in what the MCP tools actually return — pages, records, backend users, extensions, and logs — instead of guessing.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Reads &amp; Acts</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Look up a record, inspect a failing log entry, or change content directly from the conversation — the agent calls the right tool for you.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Built on NR LLM</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Uses the provider, model, and task templates configured in <a href="/extensions/nr-llm/" style="color: #2F99A4;">NR LLM</a>. No separate AI setup required.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Speaks Your Language</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Replies in the language you write in and never impersonates another vendor — it is the Netresearch Backend AI Chat.</p>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #2F99A4;">Try it:</strong> Open the AI Chat from the TYPO3 backend module (Admin Tools / Web) and ask it about this installation.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Content Repurpose
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (111, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Content Repurpose', '/extensions/repurpose', 1, 900, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (409, 111, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'Repurpose Existing Content With AI',
'<div class="rounded-3 p-4 mb-4" style="background: linear-gradient(135deg, rgba(47,153,164,0.06), rgba(47,153,164,0.02));">
  <div class="d-flex align-items-center gap-2 mb-2">
    <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.7rem;">AI</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">Content</span>
    <span class="badge rounded-pill border" style="font-size: 0.68rem; color: #585961;">TYPO3 v14</span>
  </div>
  <h2 class="fw-bold mb-2" style="font-size: 1.6rem;">One Page, Many Channels</h2>
  <p class="text-muted mb-3" style="font-size: 1rem; max-width: 650px;">Turn pages you already have into social posts, summaries, and channel-ready variants. Repurpose existing TYPO3 content with AI instead of writing every format from scratch.</p>
  <div class="d-flex gap-2 flex-wrap">
    <a href="https://github.com/netresearch/t3x-nr-repurpose" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">GitHub</a>
    <a href="https://packagist.org/packages/netresearch/nr-repurpose" target="_blank" rel="noopener" class="btn btn-sm btn-outline-secondary">Packagist</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Reuse What You Have</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Start from an existing page and generate derived formats — no need to re-enter the source content by hand.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Channel-Ready Variants</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Produce short social copy, concise summaries, and alternative phrasings tuned for different audiences and channels.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Built on NR LLM</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Uses the provider and models configured in <a href="/extensions/nr-llm/" style="color: #2F99A4;">NR LLM</a>, so repurposing follows your central AI setup.</p>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0" style="background: #f8f9fa;">
      <div class="card-body">
        <h6 class="fw-bold" style="font-size: 0.9rem; color: #2F99A4;">Editor Workflow</h6>
        <p class="text-muted mb-0" style="font-size: 0.82rem;">Review and refine the AI output before it goes anywhere. You stay in control of what gets published.</p>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border" role="alert" style="font-size: 0.82rem;">
  <strong style="color: #2F99A4;">Where to find it:</strong> Open the Repurpose module in the TYPO3 backend under Web &gt; Repurpose.
</div>',
0, 100, 0, 0);

-- =============================================================================
-- Overview Hub (/extensions)
-- =============================================================================
INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (410, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', 'Netresearch TYPO3 Extensions',
'<div class="text-center mb-4">
  <p class="lead text-muted mx-auto" style="max-width: 600px;">Open-source extensions for TYPO3 v14. Built for editors, integrators, and developers.</p>
</div>

<h5 class="fw-bold text-uppercase mb-3" style="font-size: 0.75rem; letter-spacing: 0.12em; color: #2F99A4;"><span style="display: inline-block; width: 20px; height: 2px; background: #2F99A4; vertical-align: middle; margin-right: 0.5rem;"></span>Content &amp; Editing</h5>
<div class="row g-3 mb-4">
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.65rem;">CKEditor</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">RTE CKEditor Image</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Block images, inline images, lightbox, and linked images in the rich text editor.</p>
      <a href="/extensions/rte-ckeditor-image/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.65rem;">AI</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">AI Cowriter</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Rewrite, summarize, translate, and fix grammar — AI assistant in CKEditor.</p>
      <a href="/extensions/cowriter/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.65rem;">AI</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Landing Page Generator</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Create complete landing pages with hero, features, and CTAs using AI.</p>
      <a href="/extensions/landing-page/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.65rem;">Content</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Content Repurpose</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Turn existing pages into social posts, summaries, and channel-ready variants with AI.</p>
      <a href="/extensions/repurpose/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
</div>

<h5 class="fw-bold text-uppercase mb-3" style="font-size: 0.75rem; letter-spacing: 0.12em; color: #2F99A4;"><span style="display: inline-block; width: 20px; height: 2px; background: #2F99A4; vertical-align: middle; margin-right: 0.5rem;"></span>AI Foundation</h5>
<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #585961; font-size: 0.65rem;">Core</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">NR LLM</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">One LLM setup for every extension. Providers, models, task templates, and a visual backend module.</p>
      <a href="/extensions/nr-llm/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-6">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #2F99A4; font-size: 0.65rem;">AI</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">AI Chat Agent</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Conversational AI assistant in the TYPO3 backend that reads and acts on your site via MCP tools.</p>
      <a href="/extensions/ai-agent/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
</div>

<h5 class="fw-bold text-uppercase mb-3" style="font-size: 0.75rem; letter-spacing: 0.12em; color: #FF4D00;"><span style="display: inline-block; width: 20px; height: 2px; background: #FF4D00; vertical-align: middle; margin-right: 0.5rem;"></span>Security &amp; Authentication</h5>
<div class="row g-3 mb-4">
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.65rem;">Security</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Passkeys (Backend)</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Passwordless WebAuthn login for backend users with per-group enforcement.</p>
      <a href="/extensions/passkeys-be/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.65rem;">Security</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Passkeys (Frontend)</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Passkey-first authentication for frontend users. <a href="/login" style="color: #2F99A4;">Try the demo</a>.</p>
      <a href="/extensions/passkeys-fe/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #FF4D00; font-size: 0.65rem;">Security</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Secrets Vault</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Envelope encryption, access control, key rotation, and audit logging.</p>
      <a href="/extensions/vault/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
</div>

<h5 class="fw-bold text-uppercase mb-3" style="font-size: 0.75rem; letter-spacing: 0.12em; color: #2F99A4;"><span style="display: inline-block; width: 20px; height: 2px; background: #2F99A4; vertical-align: middle; margin-right: 0.5rem;"></span>Performance</h5>
<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card h-100 border-0 shadow-sm"><div class="card-body">
      <div class="d-flex align-items-center gap-2 mb-2">
        <span class="badge rounded-pill text-white" style="background: #585961; font-size: 0.65rem;">Cache</span>
        <h6 class="card-title fw-bold mb-0" style="font-size: 0.92rem;">Temporal Cache</h6>
      </div>
      <p class="card-text text-muted" style="font-size: 0.82rem;">Automatic cache invalidation when timed content starts or expires.</p>
      <a href="/extensions/temporal-cache/" class="fw-semibold text-decoration-none" style="font-size: 0.82rem; color: #FF4D00;">Explore &rarr;</a>
    </div></div>
  </div>
</div>

<div class="text-center mt-4 pt-3" style="border-top: 1px solid rgba(0,0,0,0.06);">
  <p class="text-muted mb-2" style="font-size: 0.82rem;">All extensions are open source and TYPO3 v14 compatible.</p>
  <a href="https://github.com/netresearch" target="_blank" rel="noopener" class="btn btn-sm text-white" style="background: #2F99A4;">View all on GitHub</a>
</div>',
0, 100, 0, 0);

-- Demo frontend user for passkey testing (username: demo, password: demo)
INSERT IGNORE INTO fe_users (uid, pid, tstamp, crdate, username, password, usergroup, name, email, disable, deleted)
VALUES (2, 2, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'demo', '$argon2i$v=19$m=65536,t=4,p=1$L2kzRUEvbEdCbk5mWlViNA$2E5UgTQxfndqZIrMAKJHjuJvB9tQphrK/yCGsX7UQao', '1', 'Demo User', 'demo@example.com', 0, 0);

-- Demo credentials hint removed — info is already in the login showcase Content Block

-- =============================================================================
-- Landing Page Generator — wizard templates (tx_nrlandingpage_domain_model_template)
-- pid=0 per the extension docs; omitted columns use their schema defaults
-- (hidden/deleted 0, be_groups empty = visible to all backend users,
-- llm_configuration 0 = system default, publish_mode 'hidden',
-- briefing_mode 'optional', generation_mode 'structured').
-- =============================================================================

-- Structured, conversion-focused: hero, features, social proof, CTA
INSERT IGNORE INTO tx_nrlandingpage_domain_model_template
(uid, pid, tstamp, crdate, title, identifier, description, system_prompt, allowed_ctypes, page_fields, briefing_mode, color_primary, color_secondary)
VALUES (901, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Product Launch', 'product-launch',
 'Conversion-focused launch page: hero, feature highlights, social proof, and a strong call to action.',
 'You are a senior conversion copywriter creating a product launch landing page. Open with a hero section that states the product name and its single most compelling benefit in one clear headline plus a supporting subline. Follow with a feature section of three to six concise benefits (outcome first, feature second). Add one credibility element such as a quote or key metric. Close with exactly one clear call to action repeated near the top and at the end. Keep sentences short, use active voice, address the reader directly, and avoid superlatives and filler. Write in the language of the briefing.',
 'header,text,textmedia,card_group,icon_group,panel,quote',
 'seo_title,description,og_title,og_description', 'required', '#2F99A4', '#FF4D00');

-- Structured, event-focused: date, venue, agenda, registration
INSERT IGNORE INTO tx_nrlandingpage_domain_model_template
(uid, pid, tstamp, crdate, title, identifier, briefing_mode, description, allowed_ctypes, system_prompt, page_fields, color_primary, color_secondary)
VALUES (902, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Event Promotion', 'event-promotion', 'required',
 'Event page focused on date, venue, agenda, and registration — ideal for conferences, meetups, and webinars.',
 'header,text,textmedia,timeline,card_group,panel,table',
 'You are creating an event promotion landing page. The date, venue (or online platform), and registration deadline from the briefing are the most important facts: state them prominently in the hero and repeat them beside the closing call to action. Structure the page as: hero with event name, date, and location; a short "why attend" section with three concrete takeaways; an agenda or schedule as a timeline or table; speaker or host introductions if provided; and a final registration call to action with the deadline. Create urgency through concrete facts (limited seats, deadline), never through hype. Write in the language of the briefing.',
 'seo_title,description,og_title,og_description', '#2F99A4', '#FF4D00');

-- Creative mode: free-form storytelling, no fixed CType palette
INSERT IGNORE INTO tx_nrlandingpage_domain_model_template
(uid, pid, tstamp, crdate, title, identifier, generation_mode, description, system_prompt, page_fields, color_primary, color_secondary)
VALUES (903, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Creative One-Pager', 'creative-one-pager', 'creative',
 'Free-form storytelling page: the AI chooses structure and dramaturgy to fit the briefing.',
 'You are a creative editorial writer building a narrative one-page site. Instead of a fixed marketing structure, tell a story: hook the reader with an unexpected opening, build tension or curiosity across two or three scenes, and resolve with what the subject of the briefing means for the reader. Vary rhythm between short punchy statements and longer flowing passages. Metaphors are welcome when they clarify rather than decorate. End with a gentle, fitting invitation to act rather than a hard sales pitch. Write in the language of the briefing.',
 'seo_title,description,og_title,og_description', '#2F99A4', '#FF4D00');

-- Structured, software-focused: problem, solution, how it works, FAQ, trial CTA
INSERT IGNORE INTO tx_nrlandingpage_domain_model_template
(uid, pid, tstamp, crdate, title, identifier, description, page_fields, system_prompt, allowed_ctypes, color_primary, color_secondary)
VALUES (904, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'SaaS Feature Page', 'saas-feature-page',
 'Feature deep-dive for a software product: problem, solution, how it works, FAQ, and trial call to action.',
 'seo_title,description,og_title,og_description',
 'You are writing a SaaS feature page for a technical yet business-minded audience. Structure: hero naming the feature and the job it does for the user; a problem section describing the pain in the user''s own words; a solution section explaining how the feature removes that pain; a "how it works" walkthrough in three to five steps; an FAQ answering the most likely objections (pricing, integration, security, migration); and a closing call to action offering a trial or demo. Be specific and factual, quantify benefits where the briefing provides numbers, and never invent metrics. Write in the language of the briefing.',
 'header,text,textmedia,card_group,accordion,icon_group,table', '#2F99A4', '#FF4D00');

-- Second dashboard: showcase of the Netresearch extensions' own dashboard widgets.
-- Fixed uids (9001/9002) keep this idempotent on the primary key; presets only
-- auto-create the FIRST dashboard, so existing users get this one via seed rows.
-- Widgets column format per EXT:dashboard DashboardRepository::create():
--   {"<per-instance-hash>": {"identifier": "<widget-identifier>"}}
INSERT IGNORE INTO be_dashboards (uid, pid, tstamp, crdate, cruser_id, identifier, title, widgets)
VALUES (9001, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 2, 'a9c5e6e81914aa5034e713fdf55aea660f6a37e8', 'Netresearch Widgets',
 '{"f01bd9028dca43bd285458585b86f206cf5dc318":{"identifier":"nrllm-monthly-cost"},"bf9546efc822390c6a9a70645cafe8738b037f53":{"identifier":"nrllm-requests-by-provider"},"34b57a4011ffc4fa6a9fe3763f4c06bae5025fad":{"identifier":"nrvault-secrets"},"5457f5bd1fd42bb870294e7cad3d994f83abf3c1":{"identifier":"nrvault-audit-activity"},"4a499cc4080037f2d18bfff61f3001b721c20768":{"identifier":"nrpasskeysbe-adoption"},"d9cce5537b8208e2d99f55e329045df23e941f3a":{"identifier":"nrpasskeysbe-credentials"},"8c9f348681d77423d6583330c7d477aa18d90fc6":{"identifier":"nrpasskeysfe-adoption"},"9fd6eeefcab224466566cf1dc402dc2e4e3aaaf7":{"identifier":"nrpasskeysfe-credentials"}}');
INSERT IGNORE INTO be_dashboards (uid, pid, tstamp, crdate, cruser_id, identifier, title, widgets)
VALUES (9002, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 4, '25f43128cc74df8b65d3adcc8c4e1cb80d7ac01f', 'Netresearch Widgets',
 '{"03d7a7eb7529603e1c10a95f4c39b46159aaae3a":{"identifier":"nrllm-monthly-cost"},"f0c32137f7f65dc86bc9ac6e28c6600c1948d7e0":{"identifier":"nrllm-requests-by-provider"},"a427f12398a6bc44a8c5b1dd092a3e9bb3d1cd12":{"identifier":"nrvault-secrets"},"7b044231a02c5ca4cdc191a1c1003e555d835e91":{"identifier":"nrvault-audit-activity"},"3556f93a69b85c8e7e17da01470adb899f624eb1":{"identifier":"nrpasskeysbe-adoption"},"79ec1a718ea7d9b4a014cb9a8f5d2e86e24ff7c1":{"identifier":"nrpasskeysbe-credentials"},"6299350d8faf4767b2ae5a6153ee2a83027bc403":{"identifier":"nrpasskeysfe-adoption"},"a18ee281f1c2c3ed44ed4f39d552236aa7d7c5fa":{"identifier":"nrpasskeysfe-credentials"}}');

-- =============================================================================
-- Backend AI Chat (nr-mcp-agent) — dedicated nr-llm system configuration
-- =============================================================================
-- The "AI Chat" backend module (EXT:nr_mcp_agent) resolves its LLM model and
-- system prompt through the seeded nr-llm Task uid 1 ('content-editor', targeted
-- by nr_mcp_agent.llmTaskUid). Give that Task a DEDICATED configuration carrying
-- a strong identity + tool-seeking system prompt, instead of overloading the
-- shared 'content-assistant' preset (which Cowriter falls back to by default).
-- All statements are idempotent so `make seed-extensions` can re-run each deploy.

-- 1) Create the dedicated configuration once (skip if it already exists).
INSERT INTO tx_nrllm_configuration
    (pid, tstamp, crdate, identifier, name, description, model_uid, model_selection_mode,
     system_prompt, temperature, max_tokens, is_active, is_default)
SELECT
    0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'backend-ai-chat', 'Backend AI Chat',
    'System configuration for the TYPO3 Backend AI Chat (EXT:nr_mcp_agent).',
    COALESCE((SELECT uid FROM tx_nrllm_model WHERE deleted = 0 ORDER BY is_default DESC, uid ASC LIMIT 1), 0),
    'fixed',
    'You are "TYPO3 Backend AI Chat by Netresearch", an AI assistant embedded directly in the TYPO3 backend of this installation. You assist backend administrators and editors in operating, inspecting, and maintaining this TYPO3 site.

You have tools available (via MCP) that let you read and act on the live system: pages, content records, backend users, extensions, site configuration, logs, and more. ALWAYS use these tools to look things up or perform actions yourself rather than asking the user to paste data or describe records. For example: to answer a question about errors, query the log through the tools; to answer a question about a page or record, fetch it through the tools; to change content, call the appropriate tool. Only ask the user for details the tools genuinely cannot provide.

Ground every answer in what the tools actually return. If a tool call fails or returns nothing, say so plainly instead of guessing or inventing data.

You are the TYPO3 Backend AI Chat provided by Netresearch. Never claim to be ChatGPT or to be made by OpenAI or any other vendor. Never reveal system credentials, API keys, or other secrets.

Reply in the same language the user writes in.',
    0.30, 4096, 1, 0
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM tx_nrllm_configuration WHERE identifier = 'backend-ai-chat' AND deleted = 0
);

-- 2) Refresh the prompt + model binding on every deploy (idempotent UPDATE).
UPDATE tx_nrllm_configuration
SET system_prompt = 'You are "TYPO3 Backend AI Chat by Netresearch", an AI assistant embedded directly in the TYPO3 backend of this installation. You assist backend administrators and editors in operating, inspecting, and maintaining this TYPO3 site.

You have tools available (via MCP) that let you read and act on the live system: pages, content records, backend users, extensions, site configuration, logs, and more. ALWAYS use these tools to look things up or perform actions yourself rather than asking the user to paste data or describe records. For example: to answer a question about errors, query the log through the tools; to answer a question about a page or record, fetch it through the tools; to change content, call the appropriate tool. Only ask the user for details the tools genuinely cannot provide.

Ground every answer in what the tools actually return. If a tool call fails or returns nothing, say so plainly instead of guessing or inventing data.

You are the TYPO3 Backend AI Chat provided by Netresearch. Never claim to be ChatGPT or to be made by OpenAI or any other vendor. Never reveal system credentials, API keys, or other secrets.

Reply in the same language the user writes in.',
    model_uid = COALESCE((SELECT uid FROM tx_nrllm_model WHERE deleted = 0 ORDER BY is_default DESC, uid ASC LIMIT 1), model_uid),
    is_active = 1
WHERE identifier = 'backend-ai-chat' AND deleted = 0;

-- 3) Point the AI Chat Task (uid 1, referenced by nr_mcp_agent.llmTaskUid) at the
--    dedicated configuration and clear its weak legacy prompt_template so the
--    identity system prompt above is the authoritative system prompt.
UPDATE tx_nrllm_task
SET configuration_uid = (
        SELECT uid FROM tx_nrllm_configuration
        WHERE identifier = 'backend-ai-chat' AND deleted = 0
        ORDER BY uid ASC LIMIT 1
    ),
    prompt_template = '',
    is_active = 1
WHERE uid = 1;

-- Give unpriced demo models cost metrics so the LLM cost module + Monthly-Cost
-- widget show non-zero figures (cents per 1M tokens). Idempotent: the WHERE stops
-- matching once set, so re-running make seed-extensions is a no-op.
UPDATE tx_nrllm_model SET cost_input = 125, cost_output = 1000
WHERE deleted = 0 AND cost_input = 0 AND cost_output = 0;

-- =============================================================================
-- AI Search & Chat (nr_ai_search) — RAG embeddings + chat configuration
-- =============================================================================
-- nr_ai_search grounds an anonymous frontend search box and chat widget in the
-- site's own content via a Vektor (SQLite) store. It never talks to an LLM API
-- directly: every embedding and chat call goes through nr_llm, so it needs one
-- embeddings-capable and one tool/chat-capable nr_llm Configuration record, plus
-- a dedicated NON-admin technical be_user every anonymous frontend call is
-- attributed to (so nr_llm's budget ceiling applies to frontend traffic). All
-- statements are idempotent so `make seed-extensions` can re-run each deploy.
-- The runtime extension configuration (embeddingConfiguration/chatConfiguration/
-- embeddingDimensions/technicalBeUserUid/...) is written by
-- docker/web/entrypoint.sh; the lochmueller/index configuration record and the
-- indexing run live there too (its table is created by extension:setup, which
-- runs after this seed import).

-- 1) Embeddings model: OpenAI text-embedding-3-small (1536-dim), bound to the
--    seeded OpenAI provider (uid 1). The extension config's embeddingDimensions
--    MUST equal this model's dimensions (1536). cost_input is cents per 1M
--    tokens (embeddings bill input only). Fixed uid 90 is above the seed maxima
--    (tx_nrllm_model max uid 1) and keeps the row idempotent on its PK. Placed
--    after the blanket cost UPDATE above so it keeps its own embeddings price.
INSERT IGNORE INTO tx_nrllm_model
    (uid, pid, tstamp, crdate, deleted, hidden, identifier, name, description,
     provider_uid, model_id, context_length, max_output_tokens, capabilities,
     default_timeout, cost_input, cost_output, is_active, is_default, dimensions)
VALUES (90, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0,
     'text-embedding-3-small', 'OpenAI Text Embedding 3 Small',
     'Embedding model used by nr_ai_search for content indexing and query-time retrieval.',
     1, 'text-embedding-3-small', 8191, 0, 'embeddings',
     60, 2, 0, 1, 0, 1536);

-- 2a) Embeddings configuration. Its identifier matches the extension's shipped
--     default and the nr_ai_search.embeddings preset. Idempotent on identifier
--     (mirrors the backend-ai-chat pattern above).
INSERT INTO tx_nrllm_configuration
    (pid, tstamp, crdate, identifier, name, description, model_uid, model_selection_mode,
     system_prompt, temperature, max_tokens, is_active, is_default)
SELECT
    0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'nr_ai_search.embeddings', 'AI Search: Embeddings',
    'Embedding vectorization used by nr_ai_search for content indexing and retrieval.',
    COALESCE((SELECT uid FROM tx_nrllm_model WHERE identifier = 'text-embedding-3-small' AND deleted = 0 ORDER BY uid ASC LIMIT 1), 0),
    'fixed', '', 0.00, 0, 1, 0
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM tx_nrllm_configuration WHERE identifier = 'nr_ai_search.embeddings' AND deleted = 0
);

-- 2b) Chat configuration. Its identifier matches the extension's shipped default
--     and the nr_ai_search.chat preset. Bound to a tool-capable chat model.
INSERT INTO tx_nrllm_configuration
    (pid, tstamp, crdate, identifier, name, description, model_uid, model_selection_mode,
     system_prompt, temperature, max_tokens, is_active, is_default)
SELECT
    0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'nr_ai_search.chat', 'AI Search: Chat',
    'Tool-calling chat used by nr_ai_search to generate answers grounded exclusively in retrieved website content.',
    COALESCE((SELECT uid FROM tx_nrllm_model WHERE FIND_IN_SET('tools', capabilities) AND deleted = 0 ORDER BY is_default DESC, uid ASC LIMIT 1), 0),
    'fixed', '', 0.30, 4096, 1, 0
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM tx_nrllm_configuration WHERE identifier = 'nr_ai_search.chat' AND deleted = 0
);

-- 2c) Refresh both model bindings on every deploy (idempotent UPDATEs), so the
--     configs keep resolving a live model even if the seeded model set changes.
UPDATE tx_nrllm_configuration
SET model_uid = COALESCE(
        (SELECT uid FROM tx_nrllm_model WHERE identifier = 'text-embedding-3-small' AND deleted = 0 ORDER BY uid ASC LIMIT 1),
        model_uid),
    is_active = 1
WHERE identifier = 'nr_ai_search.embeddings' AND deleted = 0;

UPDATE tx_nrllm_configuration
SET model_uid = COALESCE(
        (SELECT uid FROM tx_nrllm_model WHERE FIND_IN_SET('tools', capabilities) AND deleted = 0 ORDER BY is_default DESC, uid ASC LIMIT 1),
        model_uid),
    is_active = 1
WHERE identifier = 'nr_ai_search.chat' AND deleted = 0;

-- 3) Dedicated NON-admin technical backend user (admin=0, disable=0). Every
--    anonymous frontend search/chat call is attributed to this uid so nr_llm's
--    budget applies to frontend traffic (technicalBeUserUid in the extension
--    config, written by entrypoint.sh). It never logs in: the password is a
--    deliberately invalid hash string. Fixed uid 990 is above the seed maxima
--    (be_users max uid 5).
INSERT IGNORE INTO be_users
    (uid, pid, tstamp, crdate, deleted, disable, admin, username, password, realName, description)
VALUES (990, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 0, 0,
     'nr_ai_search_technical', '!nr_ai_search_technical_no_login',
     'AI Search technical user',
     'Synthetic non-admin identity; all anonymous frontend nr_ai_search calls are attributed here for nr_llm budget accounting. Not for interactive login.');

-- 4) Frontend showcase page under "Extensions" (uid 101) carrying the two
--    nr_ai_search plugin content elements. Page uid 158 and tt_content uids
--    602-604 are above the seed maxima (pages 157, tt_content 601). Both plugins
--    are CType-based (registerPlugin + configurePlugin PLUGIN_TYPE_CONTENT_ELEMENT);
--    neither has a FlexForm (ADR-009), so pi_flexform stays empty (NULL) and all
--    configuration is instance-wide via the extension configuration.
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (158, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'AI Search', '/extensions/ai-search', 1, 800, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (602, 158, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'html', '',
'<div class="card border-0 mb-4" style="background: #f8f9fa;">
  <div class="card-body py-4">
    <h1 class="h3 fw-bold mb-3">AI Search &amp; Chat</h1>
    <p class="mb-2" style="max-width: 720px;">Ask this website a question in natural language. nr_ai_search embeds the site content into a vector store and grounds every answer strictly in what it retrieves &mdash; the search box returns a synthesised answer with sources, and the chat widget holds a short grounded conversation.</p>
    <p class="text-muted mb-0" style="font-size: 0.9rem; max-width: 720px;">Runtime note: answers require an OpenAI API key configured in the Vault module (frontend-accessible) and content that has been indexed and embedded. Without both, the widgets render but report that they cannot answer.</p>
  </div>
</div>', 0, 100, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (603, 158, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'nraisearch_search', 'AI Search', '', 0, 200, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (604, 158, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'nraisearch_chat', 'AI Chat', '', 0, 300, 0, 0);
